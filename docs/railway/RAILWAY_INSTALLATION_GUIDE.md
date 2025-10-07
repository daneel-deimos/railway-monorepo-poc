# Railway Installation & Deployment Guide

Complete guide for setting up and deploying your monorepo project to Railway.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start (Automated)](#quick-start-automated)
4. [Manual Setup (Alternative)](#manual-setup-alternative)
5. [Manual Actions Checklist](#manual-actions-checklist)
6. [Environment Variables](#environment-variables)
7. [Verification Steps](#verification-steps)
8. [Troubleshooting](#troubleshooting)
9. [Next Steps](#next-steps)

---

## Overview

This guide covers two approaches to deploying your project to Railway:

- **🚀 Automated Setup** (Recommended): Use our setup script that handles most of the configuration
- **🔧 Manual Setup**: Step-by-step manual process if you prefer full control

Both approaches require some manual actions in the Railway Dashboard that cannot be automated via CLI.

---

## Prerequisites

Before you begin, ensure you have:

### Required

- ✅ **Node.js** 22.13.0+ (specified in `.nvmrc`)
- ✅ **npm** 10.0.0+
- ✅ **Git** installed and repository initialized
- ✅ **GitHub account** with a repository for this project
- ✅ **Railway account** (free tier available at [railway.app](https://railway.app))

### Verification

```bash
# Check Node.js version
node -v  # Should show v22.13.0 or higher

# Check npm version
npm -v   # Should show 10.0.0 or higher

# Check git
git --version

# Check if git repo is initialized
git status  # Should not error
```

---

## Quick Start (Automated)

The automated setup script handles most of the Railway configuration for you.

### Step 1: Run the Setup Script

```bash
# From project root
npm run railway:setup
```

Or directly:

```bash
./scripts/railway-setup.sh
```

### Step 2: Follow the Prompts

The script will:

1. ✅ Check prerequisites (Node.js, git, npm)
2. ✅ Install Railway CLI if needed
3. ✅ Install project dependencies
4. ✅ Validate your local build
5. ✅ Authenticate with Railway
6. ✅ Create a new Railway project
7. ✅ Set environment variables automatically
8. ⚠️ **Pause for manual actions** (see below)
9. ✅ Push to GitHub (if confirmed)
10. ✅ Monitor deployment
11. ✅ Verify deployment health

### Step 3: Complete Manual Actions

When the script pauses, you **must** complete these actions in the Railway Dashboard:

#### 🔴 Critical: Enable Public Networking

**Without this, your deployment will fail immediately!**

1. Go to [railway.app](https://railway.app) and log in
2. Select your newly created project
3. Click on your service
4. Go to **Settings** → **Networking**
5. Click **"Generate Domain"**
6. Railway will assign a URL like: `your-app-production.up.railway.app`

#### 🔴 Critical: Connect GitHub Repository

**Required for continuous deployment:**

1. In Railway Dashboard, go to **Settings** → **Source**
2. Click **"Connect GitHub"**
3. Authorize Railway to access your GitHub account
4. Select your repository from the list
5. Choose the branch to deploy (usually `main`)

#### 🟡 Optional: Create Volume

Only needed if your app requires persistent file storage:

1. Press **Cmd+K** (Mac) or **Ctrl+K** (Windows) in Railway Dashboard
2. Type **"Create Volume"**
3. Configure:
   - **Mount Path**: `/app/data`
   - **Size**: `100MB` (sufficient for most PoCs)
4. Attach to your service

### Step 4: Confirm and Deploy

After completing the manual actions:

1. Return to your terminal
2. Confirm you've completed the manual actions
3. The script will push to GitHub and monitor the deployment
4. Wait for deployment to complete (~2-5 minutes)

### Step 5: Verify Deployment

The script will automatically:

- Display your deployment URL
- Test the health endpoint
- Save logs to `logs/railway-setup-YYYY-MM-DD-HH-MM-SS.log`

Test manually:

```bash
# Replace with your actual Railway URL
curl https://your-app-production.up.railway.app/health

# Should return:
# {"status":"ok","timestamp":"2025-10-07T...","env":"production"}
```

---

## Manual Setup (Alternative)

If you prefer to set up Railway manually or the automated script fails, follow these steps.

### Step 1: Install Railway CLI

```bash
# Install as project dependency (recommended)
npm install --save-dev @railway/cli

# Or install globally
npm install -g @railway/cli
```

### Step 2: Authenticate with Railway

```bash
npx railway login
```

This opens a browser window for authentication.

### Step 3: Initialize Railway Project

```bash
# Create a new project
npx railway init

# Link to current directory
npx railway link
```

### Step 4: Set Environment Variables

```bash
# Required for Railway deployment
npx railway variables --set NODE_ENV=production
npx railway variables --set RAILPACK_PACKAGES=nodejs@22.13.0

# For first deployment only (forces clean build)
npx railway variables --set NO_CACHE=1
```

Set any custom variables from `server/.env.example`:

```bash
# Example custom variables
npx railway variables --set EXTERNAL_API_KEY=your-key
npx railway variables --set EXTERNAL_API_SECRET=your-secret
```

### Step 5: Complete Manual Actions

Follow the [Manual Actions Checklist](#manual-actions-checklist) below to:

- Enable public networking
- Connect GitHub repository
- (Optional) Create volume

### Step 6: Deploy

```bash
# Ensure changes are committed
git add .
git commit -m "Initial Railway deployment"

# Push to GitHub (triggers Railway deployment)
git push origin main
```

### Step 7: Monitor Deployment

```bash
# Watch deployment logs
npx railway logs -f

# Or use npm script
npm run railway:logs
```

### Step 8: Remove NO_CACHE After First Deployment

Once your first deployment succeeds:

```bash
npx railway variables --unset NO_CACHE
```

---

## Manual Actions Checklist

These actions **cannot** be automated via CLI and must be done in the Railway Dashboard.

### ✅ 1. Enable Public Networking (CRITICAL)

**Status**: ⚠️ **Required** - Deployment will fail without this

**Why**: Railway services are private by default. Without public networking, your app won't be accessible and will receive SIGTERM signals immediately.

**Steps**:

1. Navigate to [railway.app](https://railway.app)
2. Select your project from the dashboard
3. Click on your service (e.g., "railway-monorepo-poc")
4. Go to **Settings** tab (top navigation)
5. Scroll to **Networking** section
6. Click **"Generate Domain"** button
7. Railway assigns a URL: `https://your-app-production.up.railway.app`

**Verification**: The domain should appear in the Networking section.

---

### ✅ 2. Connect GitHub Repository (CRITICAL)

**Status**: ⚠️ **Required** - For continuous deployment

**Why**: Enables automatic deployments when you push to GitHub.

**Steps**:

1. In your project, go to **Settings** tab
2. Find the **Source** section (first section)
3. Click **"Connect GitHub"** or **"Connect Repo"**
4. Authorize Railway to access your GitHub (if first time)
5. Select your repository from the list
6. Choose the branch to deploy (typically `main` or `master`)
7. Railway will show: "Connected to [username/repo]"

**Verification**: You should see your repo name in the Source section.

**Alternative**: You can also connect during project creation by selecting "Deploy from GitHub" option.

---

### ✅ 3. Create Volume (OPTIONAL)

**Status**: 🟡 Optional - Only if your app needs persistent storage

**When needed**:
- Storing user-generated content
- File uploads
- Application state that survives deployments
- Local database files

**When NOT needed**:
- Static assets (use git instead)
- Environment variables (use Railway variables)
- Build artifacts (regenerated each deploy)

**Steps**:

1. In Railway Dashboard, press **Cmd+K** (Mac) or **Ctrl+K** (Windows)
2. Type **"Create Volume"** in the command palette
3. Configure:
   - **Name**: `data` (or custom name)
   - **Mount Path**: `/app/data`
   - **Size**: Start with `100MB` for PoCs (can resize later)
4. Click **"Create"**
5. Volume will be attached to your service

**Verification**: Volume appears in your service's **Volumes** section.

**Access in code**:

```javascript
// server/index.js
const DATA_DIR = process.env.NODE_ENV === 'production'
  ? '/app/data'  // Railway volume mount path
  : path.join(__dirname, '..', 'data')  // Local development
```

---

### ✅ 4. Review Environment Variables (OPTIONAL)

**Status**: 🟢 Automatically set by script (if used)

**Manual verification**:

1. Go to **Settings** → **Variables** (or **Environment**)
2. Verify these are set:
   - `NODE_ENV=production`
   - `RAILPACK_PACKAGES=nodejs@22.13.0`
   - Any custom variables from your `.env.example`

**Adding more variables**:

```bash
# Via CLI
npx railway variables --set KEY=value

# Or in Dashboard: Settings → Variables → New Variable
```

---

## Environment Variables

### Required Variables

These are automatically set by the setup script:

| Variable | Value | Purpose |
|----------|-------|---------|
| `NODE_ENV` | `production` | Sets production mode for Express |
| `RAILPACK_PACKAGES` | `nodejs@22.13.0` | Specifies Node.js version for Railway |

### Optional Variables

Add these in `server/.env.example` to have them automatically set:

```bash
# server/.env.example
NODE_ENV=production
PORT=3333

# Add custom variables below:
EXTERNAL_API_KEY=your-api-key
EXTERNAL_API_SECRET=your-secret
DATABASE_URL=postgresql://...
```

### Temporary Variables

| Variable | Value | Purpose | When to Remove |
|----------|-------|---------|----------------|
| `NO_CACHE` | `1` | Forces clean build | After first successful deploy |

**Removing NO_CACHE**:

```bash
npx railway variables --unset NO_CACHE
```

---

## Verification Steps

After deployment completes, verify everything is working:

### 1. Check Deployment Status

```bash
# View current status
npx railway status

# Should show: "Status: Running"
```

### 2. Test Health Endpoint

```bash
# Get your Railway URL
npx railway domain

# Test health check
curl https://your-app-production.up.railway.app/health

# Expected response:
# {
#   "status": "ok",
#   "timestamp": "2025-10-07T12:34:56.789Z",
#   "env": "production"
# }
```

### 3. Test API Endpoint

```bash
curl https://your-app-production.up.railway.app/api/hello

# Expected response:
# {
#   "message": "Hello from Railway!",
#   "timestamp": "2025-10-07T12:34:56.789Z"
# }
```

### 4. Test Frontend

Open your Railway URL in a browser:

```bash
# Open automatically
npx railway open

# Or visit manually
open https://your-app-production.up.railway.app
```

You should see your React app with the "Test Server Connection" button working.

### 5. Check Logs

```bash
# View recent logs
npx railway logs

# Follow logs in real-time
npm run railway:logs
```

---

## Troubleshooting

### Common Issues and Solutions

#### ❌ "Deployment receives SIGTERM immediately"

**Cause**: Public networking not enabled

**Solution**:
1. Go to Railway Dashboard → Settings → Networking
2. Click "Generate Domain"
3. Wait 1-2 minutes for DNS propagation
4. Redeploy: `git commit --allow-empty -m "Trigger redeploy" && git push`

---

#### ❌ "railway: command not found"

**Cause**: Railway CLI not installed or not in PATH

**Solution**:

```bash
# If installed as project dependency, use npx:
npx railway <command>

# Or install globally:
npm install -g @railway/cli

# Or install as dev dependency:
npm install --save-dev @railway/cli
```

---

#### ❌ "No workspaces found"

**Cause**: Missing `workspaces` field in root `package.json`

**Solution**:

```json
// package.json
{
  "workspaces": ["client", "server"]
}
```

Then regenerate lockfile:

```bash
rm package-lock.json
npm install
git add package-lock.json
git commit -m "Fix workspaces configuration"
git push
```

---

#### ❌ "Build succeeds but deployment fails"

**Causes**:
- Health check failing
- Wrong port binding (must be `0.0.0.0`, not `localhost`)
- Missing `startCommand` in `railway.json`

**Solution**:

1. Check server binds to `0.0.0.0`:

```javascript
// server/index.js
const PORT = process.env.PORT || 3333
app.listen(PORT, '0.0.0.0', () => {  // ← Must be 0.0.0.0
  console.log(`Server running on port ${PORT}`)
})
```

2. Verify `railway.json`:

```json
{
  "deploy": {
    "startCommand": "cd server && npm start"
  }
}
```

3. Check logs for actual error:

```bash
npx railway logs
```

---

#### ❌ "Health check endpoint returns 404"

**Cause**: Health endpoint not configured or not accessible

**Solution**:

Ensure health endpoint is defined **before** other routes:

```javascript
// server/index.js
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    env: process.env.NODE_ENV
  })
})
```

Test locally first:

```bash
npm run dev:server
curl http://localhost:3333/health
```

---

#### ❌ "Cannot find module @rollup/rollup-linux-x64-gnu"

**Cause**: Rollup optional dependencies missing for Railway's platform

**Solution**:

Update `railway.json` build command:

```json
{
  "build": {
    "buildCommand": "npm install && cd client && npm install --force rollup && cd .. && npm run build"
  }
}
```

Or pin Rollup version in `client/package.json`:

```json
{
  "dependencies": {
    "rollup": "4.9.0"
  }
}
```

---

#### ❌ "Environment variables not loading"

**Cause**: Variables not set in Railway or not redeployed after setting

**Solution**:

1. Verify variables in Dashboard: Settings → Variables
2. Redeploy after changing variables (Railway doesn't auto-redeploy):

```bash
git commit --allow-empty -m "Trigger redeploy"
git push
```

3. Check logs to verify:

```bash
npx railway logs | grep "ENV"
```

---

#### ⚠️ "Excessive bandwidth usage"

**Cause**: Missing compression or pagination

**Solution**:

1. Verify compression is enabled:

```javascript
// server/index.js
import compression from 'compression'
app.use(compression({ level: 6 }))
```

2. Test compression locally:

```bash
curl -H "Accept-Encoding: gzip" http://localhost:3333/api/data -v
# Look for: Content-Encoding: gzip
```

3. See [railway-poc-best-practices.md](railway-poc-best-practices.md) for optimization tips

---

## Next Steps

### Monitoring

```bash
# View logs in real-time
npm run railway:logs

# Check deployment status
npx railway status

# View metrics
npx railway dashboard
```

### Updating Your App

```bash
# Make changes locally
git add .
git commit -m "Update feature"

# Push to GitHub (automatic deployment)
git push origin main

# Monitor deployment
npm run railway:logs
```

### Managing Environment Variables

```bash
# List all variables
npx railway variables

# Set a variable
npx railway variables --set KEY=value

# Remove a variable
npx railway variables --unset KEY
```

### Cost Monitoring

1. Go to Railway Dashboard → Project Settings → Usage
2. Set usage alerts:
   - Bandwidth: 500MB/month
   - Estimated cost: $4/month (80% of $5 budget)

### Rollback

If a deployment fails:

```bash
# List recent deployments
npx railway deployment list

# Redeploy a previous version
npx railway deployment redeploy <deployment-id>
```

### Useful Commands

```bash
# Open Railway Dashboard
npx railway open

# View current domain
npx railway domain

# SSH into running container (for debugging)
npx railway run bash

# Check volume usage (if using volumes)
npx railway run bash
du -sh /app/data
```

---

## Additional Resources

- **Railway Documentation**: [docs.railway.app](https://docs.railway.app)
- **Best Practices**: [railway-poc-best-practices.md](railway-poc-best-practices.md)
- **Railway Discord**: [discord.gg/railway](https://discord.gg/railway)
- **Railway Status**: [status.railway.app](https://status.railway.app)

---

## Getting Help

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review the [Best Practices](railway-poc-best-practices.md) document
3. Check Railway logs: `npm run railway:logs`
4. Review setup logs: `logs/railway-setup-*.log`
5. Ask in Railway Discord: [discord.gg/railway](https://discord.gg/railway)

---

*Last updated: 2025-10-07*
