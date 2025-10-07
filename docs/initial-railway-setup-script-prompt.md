# Initial Railway Setup Script Prompt

This document contains the prompt used to create the automated Railway deployment script and related infrastructure for this monorepo project.

---

## Context

This project is a Railway monorepo PoC (proof of concept) with a React/Vite client and Express server. We want to create an automated setup script that helps developers deploy the project to Railway with minimal manual work while following Railway best practices documented in `docs/railway/railway-poc-best-practices.md`.

---

## Prompt

I want to create a script that helps me set up a Railway project and allows me to deploy the project.

### Requirements

#### 1. Project Scope
- This project assumes you're setting up a new project for a proof of concept
- The script should handle first-time Railway deployment

#### 2. Prerequisites
- **Railway CLI**: Install Railway CLI as a project dependency (not global)
- Minimize the amount of manual work needed in the Railway UI
- All Railway CLI commands should use `npx railway` to use the project dependency

#### 3. Configuration Management
- Read from a template file (`server/.env.example`)
- Set Railway environment variables automatically from the template
- Handle required Railway-specific variables:
  - `NODE_ENV=production`
  - `RAILPACK_PACKAGES=nodejs@22.13.0`
  - `NO_CACHE=1` (for first deployment only)

#### 4. Deployment Strategy
- Support continuous deployment via GitHub integration
- Guide user through connecting GitHub repository in Railway Dashboard
- The correct flow is:
  1. Create Railway project
  2. Connect GitHub repository (creates the service)
  3. Push to GitHub (triggers deployment)
  4. Enable public networking (now that service exists)

#### 5. Safety Features
- Show a dry-run/preview mode before making changes (`--dry-run` flag)
- Confirm before destructive operations
- Create backups of Railway configurations before changes

#### 6. Automation Level
- Mostly automated with sensible defaults
- Clearly indicate which manual actions are required
- Provide step-by-step instructions for manual UI actions

#### 7. Error Handling
- **Existing Railway projects**: Error and exit (don't overwrite)
- **Failed deployments**: Support rollback
- **Missing prerequisites**: Give option to auto-install or exit with instructions

#### 8. Output & Logging
- Show verbose logs during execution
- Save logs to timestamped files in `logs/` directory
- Display deployment URLs and status at the end
- Use color-coded output (success=green, error=red, warning=yellow, info=blue)

### Implementation Requirements

#### Files to Create

1. **`scripts/railway-setup.sh`**
   - Main automated setup script
   - Executable bash script with proper error handling
   - Implements all requirements above

2. **`server/.env.example`**
   - Template file with environment variables
   - Include comments explaining each variable
   - Format:
     ```bash
     NODE_ENV=production
     PORT=3333
     # Add custom variables below
     ```

3. **`docs/railway/RAILWAY_INSTALLATION_GUIDE.md`**
   - Comprehensive installation guide
   - Cover both automated and manual setup
   - Include detailed manual actions checklist with explanations
   - Troubleshooting section for common issues
   - Step-by-step UI actions required (with context on why they're needed)

4. **`logs/.gitkeep`**
   - Create logs directory
   - Ensure it's tracked by git but log files are ignored

#### Files to Update

1. **`package.json`**
   - Add Railway CLI as devDependency: `"@railway/cli": "^4.10.0"`
   - Add scripts:
     ```json
     "railway:setup": "./scripts/railway-setup.sh",
     "railway:logs": "npx railway logs -f"
     ```

2. **`client/package.json`**
   - Add terser as devDependency (required for Vite build with minification)
   - `"terser": "^5.36.0"`

3. **`.gitignore`**
   - Add `logs/` directory (exclude log files but keep .gitkeep)
   ```
   logs/
   !logs/.gitkeep
   ```

4. **`README.md`**
   - Add Railway deployment section with:
     - Quick start: `npm run railway:setup`
     - Link to installation guide
     - Manual deployment alternative steps
     - Monitoring commands
     - Environment variables information

### Script Flow

The `railway-setup.sh` script should follow this sequence:

1. **Prerequisites Check**
   - Check Node.js version (matches `.nvmrc`)
   - Verify git repository exists
   - Check for existing Railway project (error if exists)
   - Install/verify Railway CLI as project dependency

2. **Configuration**
   - Check for `server/.env.example`, create if missing
   - Read environment variables from template
   - Validate local build (`npm run build`)

3. **Railway Project Setup**
   - Authenticate with Railway (`npx railway login`)
   - Create new project (`npx railway init`)
   - Link to current directory (`npx railway link`)
   - Set environment variables from template

4. **Manual Action: Connect GitHub** (Step 1 of 2)
   - Display instructions to connect GitHub repository in Railway Dashboard
   - Explain that this creates the service
   - Wait for user confirmation

5. **GitHub Push**
   - Verify git remote exists
   - Push current branch to GitHub
   - This triggers Railway deployment and creates the service

6. **Manual Action: Enable Public Networking** (Step 2 of 2)
   - Display instructions to enable public networking
   - Explain that deployment will fail with SIGTERM without this
   - Wait for user confirmation
   - Include optional volume creation instructions

7. **Monitor Deployment**
   - Use `timeout 30 npx railway logs` to monitor for 30 seconds
   - Save logs to file
   - Don't get stuck in follow mode

8. **Verification**
   - Get deployment URL
   - Test health endpoint
   - Display results

9. **Cleanup**
   - Remove `NO_CACHE` environment variable
   - Show summary with URLs and next steps

### Manual Actions Documentation

The script should clearly explain why manual actions are required:

**Connect GitHub Repository** (cannot be automated via CLI):
- Creates the Railway service
- Required before deployment
- Enables continuous deployment

**Enable Public Networking** (must be done after service exists):
- Railway services are private by default
- Without this, container receives SIGTERM immediately
- Must be done AFTER the service is created by GitHub connection

### Reference Documentation

Refer to `docs/railway/railway-poc-best-practices.md` for:
- Railway deployment best practices
- Common pitfalls and solutions
- Environment variable requirements
- Build and deployment configuration
- Monitoring and cost optimization

### Expected Outcome

After running `npm run railway:setup`, the developer should have:
- ✅ Railway project created and configured
- ✅ Environment variables set automatically
- ✅ GitHub connected for continuous deployment
- ✅ Public networking enabled
- ✅ First deployment completed and verified
- ✅ Logs saved for debugging
- ✅ Clear next steps and monitoring commands

The script should be idempotent where possible and provide helpful error messages when manual intervention is required.

---

## Additional Notes

### Key Learnings During Implementation

1. **Terser Dependency**: Vite 6+ requires `terser` to be explicitly installed when using `minify: 'terser'` in the config.
   - Add to `client/package.json`: `"terser": "^5.36.0"`

2. **Railway Logs Command**: The Railway CLI `logs` command doesn't support `--follow` syntax. Use `timeout` to prevent the script from hanging.

3. **Service Creation Timing**: The service is only created when GitHub is connected, not when the Railway project is initialized. Public networking cannot be enabled until the service exists.

4. **Correct Deployment Flow**:
   - ❌ Wrong: Create project → Enable networking → Connect GitHub → Deploy
   - ✅ Right: Create project → Connect GitHub → Deploy (creates service) → Enable networking

5. **Railway Build Configuration**:
   - **IMPORTANT**: Use `npm install` instead of `npm ci` in Railway builds to avoid EBUSY lock errors on cached directories like `.vite`
   - The `npm ci` command can fail with `EBUSY: resource busy or locked` errors when Railway's build cache contains locked directories
   - `npm install` is more resilient and handles cached node_modules better in Railway's containerized environment
   - Correct build command: `npm install && npm run build --workspace=client`
   - Start command should be direct: `node server/index.js` (not `cd server && npm start`)
   - Railway.json example:
     ```json
     {
       "build": {
         "builder": "RAILPACK",
         "buildCommand": "npm install && npm run build --workspace=client"
       },
       "deploy": {
         "startCommand": "node server/index.js"
       }
     }
     ```

6. **Public Networking Port**: When enabling public networking in Railway Dashboard, enter `3333` as the port (matches your server's default port)

### Testing the Script

To test the complete flow:
1. Delete the Railway project in Dashboard
2. Run `npm run railway:setup`
3. Follow the prompts for manual actions
4. Verify deployment succeeds

---

*Created: 2025-10-07*
