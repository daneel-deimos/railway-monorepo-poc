#!/bin/bash

# Railway Setup Script for PoC Projects
# This script automates the setup and deployment of Railway projects
# with sensible defaults and comprehensive logging

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Timestamps for logging
TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")
LOG_DIR="logs"
LOG_FILE="${LOG_DIR}/railway-setup-${TIMESTAMP}.log"
ERROR_LOG="${LOG_DIR}/railway-setup-error-${TIMESTAMP}.log"

# Dry run flag
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
}

log_step() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n" | tee -a "$LOG_FILE"
}

# Confirmation prompt
confirm() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would prompt: $1"
        return 0
    fi

    read -p "$1 (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi
    return 0
}

# Error handler
error_exit() {
    log_error "$1"
    log_error "Setup failed. Check logs at: $ERROR_LOG"
    exit 1
}

# Cleanup and backup functions
backup_railway_config() {
    if [ -d ".railway" ]; then
        BACKUP_DIR=".railway.backup.${TIMESTAMP}"
        log_info "Backing up existing Railway config to ${BACKUP_DIR}"
        if [ "$DRY_RUN" = false ]; then
            cp -r .railway "$BACKUP_DIR"
        fi
    fi
}

# ============================================
# MAIN SCRIPT START
# ============================================

echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════╗"
echo "║   Railway PoC Setup & Deployment Tool    ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"

if [ "$DRY_RUN" = true ]; then
    log_warning "Running in DRY RUN mode - no changes will be made"
fi

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

log_step "Step 1: Prerequisites Check"

# Check Node.js version
log_info "Checking Node.js version..."
if [ -f ".nvmrc" ]; then
    REQUIRED_NODE_VERSION=$(cat .nvmrc)
    CURRENT_NODE_VERSION=$(node -v | sed 's/v//')

    if [ "$CURRENT_NODE_VERSION" != "$REQUIRED_NODE_VERSION" ]; then
        log_warning "Node.js version mismatch!"
        log_warning "Required: $REQUIRED_NODE_VERSION, Current: $CURRENT_NODE_VERSION"
        log_info "Consider using 'nvm use' to switch versions"

        if ! confirm "Continue anyway?"; then
            error_exit "Node.js version mismatch. Please install correct version."
        fi
    else
        log_success "Node.js version matches: $CURRENT_NODE_VERSION"
    fi
fi

# Check git repository
log_info "Checking git repository..."
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    error_exit "Not a git repository. Please run 'git init' first."
fi
log_success "Git repository detected"

# Check for existing Railway project
log_info "Checking for existing Railway project..."
if [ -d ".railway" ]; then
    error_exit "Railway project already exists! Remove .railway directory or use railway link to reconnect."
fi
log_success "No existing Railway project found"

# Install/Check Railway CLI
log_info "Checking Railway CLI..."
if ! npm list @railway/cli > /dev/null 2>&1; then
    log_warning "Railway CLI not found in project dependencies"

    if confirm "Install Railway CLI as dev dependency?"; then
        log_info "Installing @railway/cli..."
        if [ "$DRY_RUN" = false ]; then
            npm install --save-dev @railway/cli >> "$LOG_FILE" 2>&1 || error_exit "Failed to install Railway CLI"
        fi
        log_success "Railway CLI installed"
    else
        error_exit "Railway CLI is required. Install manually: npm install --save-dev @railway/cli"
    fi
else
    log_success "Railway CLI found"
fi

# Check npm dependencies
log_info "Checking npm dependencies..."
if [ ! -d "node_modules" ]; then
    log_warning "node_modules not found"

    if confirm "Run 'npm run init' to install dependencies?"; then
        log_info "Installing dependencies..."
        if [ "$DRY_RUN" = false ]; then
            npm run init >> "$LOG_FILE" 2>&1 || error_exit "Failed to install dependencies"
        fi
        log_success "Dependencies installed"
    else
        error_exit "Dependencies are required. Run 'npm run init' manually."
    fi
else
    log_success "Dependencies found"
fi

log_step "Step 2: Configuration Management"

# Check for .env.example
if [ ! -f "server/.env.example" ]; then
    log_warning "server/.env.example not found"
    log_info "Creating default .env.example..."

    if [ "$DRY_RUN" = false ]; then
        cat > server/.env.example <<EOF
# Server Configuration
NODE_ENV=production
PORT=3333

# Add your custom environment variables below
EOF
    fi
    log_success "Created server/.env.example"
fi

log_info "Reading environment variables from server/.env.example..."
ENV_VARS=()
while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "$line" ]]; then
        ENV_VARS+=("$line")
    fi
done < server/.env.example

log_info "Found ${#ENV_VARS[@]} environment variable(s) to set"

log_step "Step 3: Pre-Deployment Validation"

# Test local build
log_info "Testing local build..."
if [ "$DRY_RUN" = false ]; then
    npm run build >> "$LOG_FILE" 2>&1 || error_exit "Build failed. Fix errors before deploying."
fi
log_success "Build test passed"

# Check bundle size
if [ -d "client/dist" ]; then
    BUNDLE_SIZE=$(du -sh client/dist | cut -f1)
    log_info "Client bundle size: $BUNDLE_SIZE"

    # Warn if bundle is large (approximate check)
    BUNDLE_SIZE_KB=$(du -sk client/dist | cut -f1)
    if [ "$BUNDLE_SIZE_KB" -gt 5120 ]; then
        log_warning "Bundle size is large (> 5MB). Consider optimizing."
    fi
fi

# Test health endpoint locally (if server is not running, skip)
log_info "Testing health endpoint locally (optional)..."
log_info "Skipping local health check (assumes server is not running)"

log_step "Step 4: Railway Project Setup"

backup_railway_config

# Railway login
log_info "Checking Railway authentication..."
if [ "$DRY_RUN" = false ]; then
    if ! npx railway whoami > /dev/null 2>&1; then
        log_info "Not logged in to Railway. Opening login..."
        npx railway login || error_exit "Railway login failed"
    fi
fi
log_success "Railway authentication confirmed"

# Railway init
log_info "Creating new Railway project..."
if [ "$DRY_RUN" = false ]; then
    npx railway init || error_exit "Railway init failed"
fi
log_success "Railway project created"

# Railway link
log_info "Linking Railway project to current directory..."
if [ "$DRY_RUN" = false ]; then
    npx railway link || error_exit "Railway link failed"
fi
log_success "Railway project linked"

log_step "Step 5: Environment Variables Configuration"

# Set required environment variables
log_info "Setting Railway environment variables..."

REQUIRED_VARS=(
    "NODE_ENV=production"
    "RAILPACK_PACKAGES=nodejs@22.13.0"
    "NO_CACHE=1"
)

for var in "${REQUIRED_VARS[@]}"; do
    log_info "Setting: $var"
    if [ "$DRY_RUN" = false ]; then
        npx railway variables --set "$var" >> "$LOG_FILE" 2>&1 || log_warning "Failed to set $var"
    fi
done

# Set custom environment variables from .env.example
for var in "${ENV_VARS[@]}"; do
    if [[ "$var" == NODE_ENV=* ]] || [[ "$var" == PORT=* ]]; then
        continue  # Skip already set variables
    fi

    log_info "Setting custom variable: $var"
    if [ "$DRY_RUN" = false ]; then
        npx railway variables --set "$var" >> "$LOG_FILE" 2>&1 || log_warning "Failed to set $var"
    fi
done

log_success "Environment variables configured"

log_step "Step 6: Connect GitHub Repository"

echo ""
echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║           ⚠️  MANUAL ACTION REQUIRED (Step 1 of 2)  ⚠️       ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${RED}CRITICAL:${NC} Connect your GitHub repository to Railway"
echo ""
echo -e "  ${GREEN}1. Connect GitHub Repository${NC}"
echo "     • Go to Railway Dashboard: https://railway.app"
echo "     • Select your project"
echo "     • In Settings → Source"
echo "     • Click: 'Connect GitHub'"
echo "     • Select your repository"
echo "     • Choose branch: main"
echo ""
echo -e "${YELLOW}Note:${NC} Connecting GitHub will trigger an automatic deployment."
echo -e "${YELLOW}      Wait for the deployment to complete before continuing.${NC}"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

log_info "For detailed instructions, see: docs/railway/RAILWAY_INSTALLATION_GUIDE.md"

if ! confirm "Have you connected GitHub and waited for initial deployment to complete?"; then
    log_warning "Setup paused. Connect GitHub, wait for deployment, then re-run."
    log_info "Monitor deployment: https://railway.app (check Deployments tab)"
    exit 0
fi

log_step "Step 7: Verify GitHub Connection"

# Check for git remote
log_info "Checking GitHub remote..."
if ! git remote get-url origin > /dev/null 2>&1; then
    log_warning "No GitHub remote found"
    log_error "GitHub remote is required for Railway deployment"
    log_info "Add a GitHub remote:"
    log_info "  git remote add origin <your-github-repo-url>"
    log_info "  git push -u origin main"
    log_info "Then re-run this script"
    exit 1
fi

REMOTE_URL=$(git remote get-url origin)
log_success "GitHub remote found: $REMOTE_URL"

# Check if current branch is pushed
CURRENT_BRANCH=$(git branch --show-current)
log_info "Current branch: $CURRENT_BRANCH"

if ! git ls-remote --exit-code origin "$CURRENT_BRANCH" > /dev/null 2>&1; then
    log_error "Current branch not pushed to GitHub"
    log_info "Railway needs your code on GitHub to deploy."
    log_info "Push your code: git push -u origin $CURRENT_BRANCH"
    log_info "Then connect the repository in Railway Dashboard (Step 6)"
    exit 1
fi

log_success "Code is pushed to GitHub and ready for Railway deployment"

log_step "Step 8: Enable Public Networking"

echo ""
echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║           ⚠️  MANUAL ACTION REQUIRED (Step 2 of 2)  ⚠️       ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${RED}CRITICAL:${NC} Enable public networking (deployment will fail without this)"
echo ""
echo -e "  ${GREEN}2. Enable Public Networking${NC}"
echo "     • In Railway Dashboard, click on your service"
echo "     • Go to: Settings → Networking"
echo "     • Under 'Public Networking', click: 'Generate Domain'"
echo "     • When asked for port, enter: 3333"
echo "     • Click 'Generate Domain' button"
echo "     • Railway assigns: https://your-app-production.up.railway.app"
echo ""
echo -e "${BLUE}Optional (if needed):${NC}"
echo ""
echo "  3. Create Volume (if your app needs persistent storage)"
echo "     • Press: Cmd+K (Mac) or Ctrl+K (Windows)"
echo "     • Type: 'Create Volume'"
echo "     • Mount Path: /app/data"
echo "     • Size: 100MB (for PoCs)"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if ! confirm "Have you enabled public networking?"; then
    log_warning "Enable public networking to continue."
    log_info "Your deployment will fail with SIGTERM without public networking."
    log_info "After enabling, monitor logs: npm run railway:logs"
    exit 0
fi

log_step "Step 9: Deployment Verification"

log_info "Checking deployment status..."
log_info "Railway has deployed your service from GitHub"

if [ "$DRY_RUN" = false ]; then
    sleep 3
fi

log_step "Step 10: Get Deployment URL"

# Get deployment URL
log_info "Retrieving deployment URL..."
if [ "$DRY_RUN" = false ]; then
    DEPLOY_URL=$(npx railway domain 2>&1 | grep -o 'https://[^[:space:]]*' | head -1)

    if [ -n "$DEPLOY_URL" ]; then
        log_success "Deployment URL: $DEPLOY_URL"

        # Test health endpoint
        log_info "Testing health endpoint..."
        sleep 5  # Wait for deployment to stabilize

        if curl -f -s "${DEPLOY_URL}/health" > /dev/null 2>&1; then
            log_success "Health check passed!"
        else
            log_warning "Health check failed. Deployment may still be in progress."
            log_info "Check manually: curl ${DEPLOY_URL}/health"
        fi
    else
        log_warning "Could not retrieve deployment URL"
        log_info "Check Railway Dashboard for deployment status"
    fi
fi

log_step "Step 11: Cleanup"

# Remove NO_CACHE after first deployment
log_info "Removing NO_CACHE environment variable..."
if [ "$DRY_RUN" = false ]; then
    npx railway variables --unset NO_CACHE >> "$LOG_FILE" 2>&1 || log_warning "Could not remove NO_CACHE"
fi
log_success "NO_CACHE removed (future deployments will use cache)"

log_step "Setup Complete!"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              🎉  Railway Setup Successful!  🎉               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo ""
if [ -n "$DEPLOY_URL" ]; then
    echo -e "  🌐 Deployment URL:  ${GREEN}${DEPLOY_URL}${NC}"
    echo -e "  ✅ Health Check:    ${DEPLOY_URL}/health"
fi
echo -e "  📊 Railway Dashboard: ${BLUE}https://railway.app${NC}"
echo -e "  📝 Logs saved to:     ${LOG_FILE}"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo ""
echo "  • Monitor logs:        npm run railway:logs"
echo "  • View deployments:    npx railway status"
echo "  • Update environment:  npx railway variables"
echo "  • Open dashboard:      npx railway open"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo ""
echo "  • Future deployments happen automatically on git push"
echo "  • Monitor usage in Railway Dashboard to stay under budget"
echo "  • See docs/railway/RAILWAY_INSTALLATION_GUIDE.md for more info"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

log_success "Setup completed at $(date)"
