# Railway PoC Best Practices - Lessons Learned

**Based on:** Railway monorepo deployment experience
**Generated:** 2025-10-06
**Target:** Future proof-of-concept projects on Railway

---

## Executive Summary

This guide distills key learnings from deploying a real-world PoC on Railway, focusing on **avoiding pitfalls**, **minimizing costs**, and **getting to production fast**. These practices are specifically tailored for **quick prototypes** with a **$5/month budget**.

### Golden Rules for Railway PoCs

1. ✅ **Design for bandwidth efficiency from day 1** - This is your primary cost driver
2. ✅ **Start with compression and caching** - Not optional, essential
3. ✅ **Use minimal data structures** - Don't transfer what you don't need
4. ✅ **Test the deployment process early** - Don't wait until the app is "done"
5. ✅ **Monitor from day 1** - Know your usage patterns immediately

---

## Project Setup Checklist

### 1. Initial Project Structure

**Recommended Structure for Monorepo:**

```
your-poc-project/
├── .nvmrc                    # Node version
├── .node-version             # Railway reads this
├── .gitignore                # Essential exclusions
├── .dockerignore             # Deployment exclusions
├── railway.json              # Railway configuration
├── package.json              # Root with workspaces
├── package-lock.json         # Keep in sync!
├── README.md
├── CLAUDE.md                 # Project guidance for AI
├── docs/
│   ├── railway/              # Deployment notes
│   └── USER_GUIDE.md
├── client/                   # Frontend workspace
│   ├── package.json
│   ├── vite.config.js
│   └── src/
└── server/                   # Backend workspace
    ├── package.json
    └── index.js
```

**Why This Structure:**
- Clear separation of concerns
- Railway handles monorepos well (with correct setup)
- Easy to develop locally
- Single deployment pipeline

---

### 2. Essential Configuration Files

#### `.nvmrc` and `.node-version`

**Always specify Node version explicitly:**

```
22.13.0
```

**Why:**
- Railway won't guess correctly
- Vite 7+ requires Node 22.12+
- Avoids "works locally, fails on Railway" issues

**Lesson Learned:** We had 4 failed deployments because Railway defaulted to Node 20.18.1

---

#### `railway.json`

**Start with this template:**

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "RAILPACK",
    "buildCommand": "npm install && npm run build"
  },
  "deploy": {
    "startCommand": "cd server && npm start",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```

**Key Points:**
- Use **RAILPACK** (not NIXPACKS) - it's newer and better for Node.js
- Keep buildCommand simple if possible
- Limit retries to 3 (not 10) - fail fast
- Explicit startCommand avoids confusion

**If you have complex build needs:**

```json
{
  "build": {
    "builder": "RAILPACK",
    "buildCommand": "npm install && npm run build && npm run post-build"
  }
}
```

**⚠️ Avoid:** Multiple `cd` commands unless absolutely necessary

---

#### `package.json` (Root)

**Minimal root package.json for monorepo:**

```json
{
  "name": "your-poc",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "engines": {
    "node": ">=22.12.0",
    "npm": ">=10.0.0"
  },
  "workspaces": [
    "client",
    "server"
  ],
  "scripts": {
    "dev:client": "cd client && npm run dev",
    "dev:server": "cd server && npm run dev",
    "dev": "npm run dev:server & npm run dev:client",
    "build": "npm run build --workspace=client",
    "start": "cd server && npm start"
  },
  "devDependencies": {
    "@railway/cli": "^4.10.0"
  }
}
```

**Critical:**
- ✅ Include `workspaces` array
- ✅ Include `engines` field
- ✅ Use `type: "module"` for ESM
- ✅ Define `build` and `start` scripts

**Lesson Learned:** Missing `workspaces` caused "No workspaces found" error

---

#### `.gitignore`

**Essential exclusions:**

```gitignore
# Dependencies
node_modules/
package-lock.json        # If using npm workspaces, keep this OUT of gitignore

# Build outputs
dist/
build/
.vite/

# Environment
.env
.env.local
.env.production

# Data files (large)
data/*.json              # Exclude large data files
!data/*-test.json        # But keep test data

# OS files
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/

# Logs
*.log
npm-debug.log*

# Railway
.railway/
```

**⚠️ Important:**
- Do NOT exclude `package-lock.json` - Railway needs it
- Exclude large data files (use volumes instead)
- Keep test data in git for development

---

#### `.dockerignore`

**Reduce build time by excluding unnecessary files:**

```dockerignore
# Source control
.git/
.github/

# Documentation (exclude from builds)
docs/
*.md
!README.md

# Development files
.vscode/
.idea/
.DS_Store

# Node modules (will be reinstalled)
node_modules/
*/node_modules/

# Build artifacts
dist/
build/

# Logs and temp files
*.log
tmp/
temp/

# Large data directories
data-backups/
downloads/
uploads/

# Test files (if large)
*.test.js
*.spec.js
__tests__/
```

**Why:** Faster uploads, smaller context for builds

---

### 3. Server Configuration for Railway

#### Essential Server Setup

**server/index.js template:**

```javascript
import 'dotenv/config'
import express from 'express'
import compression from 'compression'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const app = express()
const PORT = process.env.PORT || 3001
const NODE_ENV = process.env.NODE_ENV || 'development'

// 1. COMPRESSION (Essential for cost savings)
app.use(compression({
  level: 6,
  threshold: 1024 // Only compress responses > 1KB
}))

// 2. JSON parsing
app.use(express.json({ limit: '10mb' }))

// 3. Health check BEFORE other routes (Railway needs this)
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    env: NODE_ENV
  })
})

// 4. API routes
app.get('/api/data', async (req, res) => {
  // Set cache headers
  res.set('Cache-Control', 'public, max-age=300')

  // Your logic here
  res.json({ message: 'Hello Railway!' })
})

// 5. Static files (production only)
if (NODE_ENV === 'production') {
  const clientBuildPath = path.join(__dirname, '..', 'client', 'dist')
  app.use(express.static(clientBuildPath))

  // SPA fallback
  app.get('*', (req, res) => {
    res.sendFile(path.join(clientBuildPath, 'index.html'))
  })
}

// 6. Bind to 0.0.0.0 (NOT localhost)
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`)
  console.log(`Environment: ${NODE_ENV}`)
  console.log('Ready to accept connections')
})

// 7. Graceful shutdown (Railway sends SIGTERM)
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server...')
  server.close(() => {
    console.log('Server closed')
    process.exit(0)
  })
})

process.on('SIGINT', () => {
  console.log('SIGINT received, closing server...')
  server.close(() => {
    console.log('Server closed')
    process.exit(0)
  })
})
```

**Critical Points:**

✅ **Compression** - Reduces bandwidth by 60-80%
✅ **0.0.0.0 binding** - `localhost` won't work in containers
✅ **Health check endpoint** - Railway uses this
✅ **Graceful shutdown** - Handle SIGTERM/SIGINT
✅ **Cache headers** - Reduce redundant requests
✅ **Environment detection** - Different paths for dev/prod

**Lesson Learned:** Binding to `localhost` caused "SIGTERM received immediately" errors

---

### 4. Client Configuration

#### Vite Config for Production

**client/vite.config.js:**

```javascript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],

  // Important for Railway deployment
  server: {
    host: true,
    port: 3000
  },

  // Build optimizations
  build: {
    outDir: 'dist',
    sourcemap: false, // Disable in production to save space
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: {
          // Split vendor code for better caching
          vendor: ['react', 'react-dom', 'react-router-dom']
        }
      }
    }
  },

  // API proxy for local development
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        changeOrigin: true
      }
    }
  }
})
```

**Key Points:**
- Disable sourcemaps in production (saves space)
- Split vendor chunks for caching
- Use API proxy for local dev
- No need for VITE_API_URL in production (same domain)

---

### 5. Environment Variables Strategy

#### Recommended Approach

**Local Development (.env):**
```bash
NODE_ENV=development
PORT=3001

# External API credentials
EXTERNAL_API_KEY=your-key
EXTERNAL_API_SECRET=your-secret
```

**Railway (Dashboard):**
```
NODE_ENV=production
RAILPACK_PACKAGES=nodejs@22.13.0

# External API credentials
EXTERNAL_API_KEY=prod-key
EXTERNAL_API_SECRET=prod-secret

# Optional: Force clean build (remove after first success)
NO_CACHE=1
```

**⚠️ Security:**
- Never commit `.env` to git
- Use Railway's environment variables UI
- Rotate secrets regularly

**💡 Tip:** Railway auto-provides useful variables:
- `PORT` - Use this, don't hardcode
- `RAILWAY_ENVIRONMENT` - production/staging
- `RAILWAY_PROJECT_NAME`
- `RAILWAY_PUBLIC_DOMAIN`

---

## Data Management Best Practices

### 1. Volume Configuration

**When to Use Volumes:**
- ✅ User-generated content (posts, tags, etc.)
- ✅ Application state that must persist
- ✅ Files that change at runtime

**When NOT to Use Volumes:**
- ❌ Static assets (use git or CDN)
- ❌ Dependencies (node_modules)
- ❌ Build artifacts

**Recommended Size for PoC:**

```
Small dataset (<1000 records):     100MB
Medium dataset (1K-10K records):   500MB
Large dataset (10K-100K records):  1-2GB
```

**⚠️ Don't Over-Provision:**
- Start small (100MB)
- Scale up as needed
- Monitor with `du -sh /app/data`

**Lesson Learned:** We allocated 1GB but only used 1.1MB (0.11% utilization)

---

### 2. File-Based Storage Strategy

**For PoCs, JSON files are fine if:**
- ✅ Dataset < 10,000 records
- ✅ Writes are infrequent
- ✅ No complex queries needed
- ✅ Single instance deployment

**Storage Structure:**

```javascript
// server/index.js
const DATA_DIR = process.env.NODE_ENV === 'production'
  ? '/app/data'  // Railway volume mount
  : path.join(__dirname, '..', 'data') // Local development

const USERS_FILE = path.join(DATA_DIR, 'users.json')
const POSTS_FILE = path.join(DATA_DIR, 'posts.json')

// Ensure directory exists
import fs from 'fs/promises'
try {
  await fs.access(DATA_DIR)
} catch {
  await fs.mkdir(DATA_DIR, { recursive: true })
}
```

**Read/Write Helpers:**

```javascript
// Read with fallback
async function readJSON(filepath, defaultValue = []) {
  try {
    const data = await fs.readFile(filepath, 'utf-8')
    return JSON.parse(data)
  } catch (error) {
    if (error.code === 'ENOENT') {
      return defaultValue
    }
    throw error
  }
}

// Write (optimized for production)
async function writeJSON(filepath, data) {
  const jsonString = process.env.NODE_ENV === 'production'
    ? JSON.stringify(data) // No indentation (saves space)
    : JSON.stringify(data, null, 2) // Pretty for development

  await fs.writeFile(filepath, jsonString)
}
```

**When to Migrate to Database:**
- Dataset > 10,000 records
- Complex queries needed
- Multiple concurrent users
- Need transactions

---

### 3. Data Upload Strategies

**Problem:** Railway volumes start empty

**Solution Options:**

**Option A: Test Data in Git (Recommended for PoC)**

```bash
# Create small test dataset
node scripts/create-test-data.js

# Commit to git
git add data/test-data.json
git commit -m "Add test data for development"
```

```javascript
// Server loads test data on first run
if (process.env.NODE_ENV === 'production') {
  const testDataPath = path.join(__dirname, 'test-data.json')
  const prodDataPath = path.join(DATA_DIR, 'data.json')

  try {
    await fs.access(prodDataPath)
  } catch {
    // Copy test data to production volume
    const testData = await fs.readFile(testDataPath, 'utf-8')
    await fs.writeFile(prodDataPath, testData)
    console.log('Initialized with test data')
  }
}
```

**Option B: Railway CLI Upload (For larger datasets)**

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and link
railway login
railway link

# Upload data
railway run bash
# Inside Railway shell:
cat > /app/data/your-data.json
# Paste content, Ctrl+D to save
```

**Option C: Admin Upload Endpoint (Most flexible)**

```javascript
// Temporary admin endpoint (protect with secret!)
app.post('/admin/upload', async (req, res) => {
  const { secret, filename, data } = req.body

  if (secret !== process.env.ADMIN_SECRET) {
    return res.status(403).json({ error: 'Forbidden' })
  }

  const filepath = path.join(DATA_DIR, filename)
  await writeJSON(filepath, data)

  res.json({ success: true, filename })
})
```

Then upload via curl:
```bash
curl -X POST https://your-app.railway.app/admin/upload \
  -H "Content-Type: application/json" \
  -d @local-data.json
```

**⚠️ Security:** Remove admin endpoints after initial setup!

---

## Bandwidth Optimization from Day 1

### 1. Response Compression (Essential)

**Always enable compression:**

```bash
cd server
npm install compression
```

```javascript
import compression from 'compression'

app.use(compression({
  level: 6, // Good balance
  threshold: 1024 // Only compress > 1KB
}))
```

**Impact:** 60-80% bandwidth reduction

---

### 2. Cache Headers (Essential)

**Add to all GET endpoints:**

```javascript
// Helper function
function cacheControl(seconds) {
  return (req, res, next) => {
    res.set('Cache-Control', `public, max-age=${seconds}`)
    next()
  }
}

// Static data (rarely changes)
app.get('/api/config', cacheControl(3600), async (req, res) => {
  // Cache for 1 hour
})

// Dynamic data (changes frequently)
app.get('/api/posts', cacheControl(300), async (req, res) => {
  // Cache for 5 minutes
})
```

**Impact:** 50% reduction in redundant requests

---

### 3. Minimal Response Structures

**Bad (sends everything):**
```javascript
app.get('/api/posts', async (req, res) => {
  const posts = await readJSON(POSTS_FILE)
  res.json(posts) // Sends all fields
})
```

**Good (sends only what's needed):**
```javascript
app.get('/api/posts', async (req, res) => {
  const posts = await readJSON(POSTS_FILE)

  // Only return necessary fields
  const minimal = posts.map(post => ({
    id: post.id,
    title: post.title,
    timestamp: post.timestamp,
    // Exclude large fields like content, images
  }))

  res.json(minimal)
})

// Separate endpoint for full post
app.get('/api/posts/:id', cacheControl(600), async (req, res) => {
  const posts = await readJSON(POSTS_FILE)
  const post = posts.find(p => p.id === req.params.id)
  res.json(post) // Full details only when needed
})
```

**Impact:** 30-50% reduction in list endpoint payloads

---

### 4. Pagination from Day 1

**Always paginate lists:**

```javascript
app.get('/api/posts', async (req, res) => {
  const page = parseInt(req.query.page) || 1
  const limit = parseInt(req.query.limit) || 20

  const posts = await readJSON(POSTS_FILE)

  const startIndex = (page - 1) * limit
  const endIndex = startIndex + limit
  const paginatedPosts = posts.slice(startIndex, endIndex)

  res.json({
    posts: paginatedPosts,
    pagination: {
      page,
      limit,
      total: posts.length,
      totalPages: Math.ceil(posts.length / limit),
      hasMore: endIndex < posts.length
    }
  })
})
```

**Impact:** Scales gracefully, no matter dataset size

---

### 5. Client-Side Request Optimization

**Debounce rapid requests:**

```javascript
import debounce from 'lodash.debounce'
import { useCallback } from 'react'

const debouncedSave = useCallback(
  debounce(async (data) => {
    await fetch('/api/save', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    })
  }, 1000), // Wait 1 second after last change
  []
)
```

**Lazy load images:**

```javascript
import { LazyLoadImage } from 'react-lazy-load-image-component'

<LazyLoadImage
  src={post.imageUrl}
  alt={post.title}
  effect="blur"
  threshold={200}
/>
```

---

## Testing Before Deployment

### Local Testing Checklist

**Before pushing to Railway:**

1. ✅ Test build locally
   ```bash
   npm run build
   cd server && npm start
   # Visit http://localhost:3001
   ```

2. ✅ Test with production environment variables
   ```bash
   NODE_ENV=production npm start
   ```

3. ✅ Check bundle size
   ```bash
   npm run build
   du -sh client/dist
   # Should be < 5MB for PoCs
   ```

4. ✅ Test health check endpoint
   ```bash
   curl http://localhost:3001/health
   # Should return 200 OK
   ```

5. ✅ Verify compression works
   ```bash
   curl -H "Accept-Encoding: gzip" http://localhost:3001/api/data -v
   # Look for "Content-Encoding: gzip" in response headers
   ```

---

### First Deployment Strategy

**Step 1: Create Railway Project**

```bash
# Option A: Via Dashboard
# 1. Go to railway.app/new
# 2. Deploy from GitHub repo
# 3. Select your repository

# Option B: Via CLI (recommended for PoCs)
railway login
railway init
railway link
```

**Step 2: Enable Public Networking IMMEDIATELY**

```
⚠️ DO THIS FIRST or your deployment will fail!

1. Go to Settings → Networking
2. Click "Generate Domain"
3. Railway assigns: your-app-production.up.railway.app
```

**Lesson Learned:** We had SIGTERM errors because public networking wasn't enabled

---

**Step 3: Set Environment Variables**

**Minimum required:**
```
NODE_ENV=production
RAILPACK_PACKAGES=nodejs@22.13.0
```

**For first deployment:**
```
NO_CACHE=1    # Force clean build
```

**Remove `NO_CACHE` after first successful deployment!**

---

**Step 4: Create Volume (if needed)**

```
1. Press Cmd+K (Mac) or Ctrl+K (Windows)
2. Type "Create Volume"
3. Configure:
   - Mount Path: /app/data
   - Size: 100MB (for PoCs)
```

---

**Step 5: Deploy**

```bash
git add .
git commit -m "Initial Railway deployment"
git push origin main

# Railway auto-deploys on push
```

**Monitor deployment:**
```bash
railway logs
# or via Dashboard → Deployments → View Logs
```

---

**Step 6: Verify Deployment**

```bash
export RAILWAY_URL="https://your-app-production.up.railway.app"

# Health check
curl $RAILWAY_URL/health

# API endpoints
curl $RAILWAY_URL/api/data

# Frontend
open $RAILWAY_URL
```

---

## Monitoring & Cost Control

### 1. Set Up Usage Alerts (Day 1)

**Railway Dashboard:**
1. Project Settings → Usage Alerts
2. Set thresholds:
   - Bandwidth: 500MB/month
   - Estimated cost: $4/month (80% of $5 budget)
   - Deployment failures: 2 consecutive

---

### 2. Enable Logging Middleware

**Track response sizes:**

```javascript
app.use((req, res, next) => {
  const start = Date.now()
  const originalJson = res.json

  res.json = function(data) {
    const sizeKB = Buffer.byteLength(JSON.stringify(data)) / 1024
    const duration = Date.now() - start

    if (sizeKB > 100) {
      console.log(`📊 ${req.method} ${req.path} | ${sizeKB.toFixed(1)}KB | ${duration}ms`)
    }

    return originalJson.call(this, data)
  }

  next()
})
```

**Check logs weekly:**
```bash
railway logs | grep "📊"
```

---

### 3. Monitor Volume Usage

**Check periodically:**

```bash
railway run bash
du -sh /app/data
df -h /app/data
```

**Set up automated monitoring:**

```javascript
// Add to server startup
import fs from 'fs'
import { execSync } from 'child_process'

if (process.env.NODE_ENV === 'production') {
  const volumeUsage = execSync('du -sh /app/data').toString()
  console.log(`📦 Volume usage: ${volumeUsage.trim()}`)
}
```

---

### 4. Weekly Cost Review

**Check Railway Dashboard:**
- Current month usage
- Bandwidth consumed
- Estimated cost
- Deployment frequency

**Calculate cost per feature:**
```
Total bandwidth this week: 150MB
Feature A traffic: 100MB (67%)
Feature B traffic: 50MB (33%)

Feature A needs optimization!
```

---

## Deployment Workflow for Iterations

### Quick Deploy (Minor Changes)

```bash
git add .
git commit -m "Fix button styling"
git push origin main

# Railway auto-deploys
# Monitor: railway logs -f
```

---

### Major Changes (Test Locally First)

```bash
# 1. Test build locally
npm run build
NODE_ENV=production npm start

# 2. Test on production-like data
# Use test dataset that mimics production size

# 3. Check bundle size
du -sh client/dist

# 4. Deploy
git add .
git commit -m "feat: Add new feature"
git push origin main

# 5. Monitor deployment
railway logs -f

# 6. Verify health check
curl https://your-app.railway.app/health

# 7. Smoke test key features
```

---

### Rollback Strategy

**If deployment fails:**

```bash
# Option 1: Redeploy previous version
railway deployment list
railway deployment redeploy <previous-deployment-id>

# Option 2: Git revert
git revert HEAD
git push origin main
```

**Prevention:**
- Keep commits small
- Test locally before pushing
- Monitor logs immediately after deploy

---

## Common Pitfalls & Solutions

### Pitfall 1: "Workspace not found" Error

**Symptom:**
```
npm error No workspaces found:
npm error   --workspace=client
```

**Solution:**
Add to root `package.json`:
```json
{
  "workspaces": ["client", "server"]
}
```

Then regenerate lockfile:
```bash
rm package-lock.json
npm install
git add package-lock.json
git commit -m "Fix workspaces"
```

---

### Pitfall 2: Rollup Optional Dependencies Missing

**Symptom:**
```
Error: Cannot find module @rollup/rollup-linux-x64-gnu
```

**Solution:**
Update `railway.json`:
```json
{
  "build": {
    "buildCommand": "npm install && cd client && npm install --force rollup && cd .. && npm run build"
  }
}
```

**Alternative:** Pin Rollup version in client/package.json
```json
{
  "dependencies": {
    "rollup": "4.9.0"
  }
}
```

---

### Pitfall 3: Server Immediately Stops (SIGTERM)

**Symptom:**
```
Server running on http://0.0.0.0:8080
Stopping Container
npm error signal SIGTERM
```

**Root Cause:** Public networking not enabled

**Solution:**
1. Settings → Networking
2. Click "Generate Domain"
3. Redeploy

---

### Pitfall 4: localhost Binding

**Symptom:**
Server starts but Railway URL is unreachable

**Solution:**
Bind to `0.0.0.0`:
```javascript
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`)
})
```

**Not:**
```javascript
app.listen(PORT, 'localhost', ...) // ❌ Won't work
app.listen(PORT, '127.0.0.1', ...) // ❌ Won't work
```

---

### Pitfall 5: Environment Variables Not Loading

**Symptom:**
`process.env.MY_VAR` is undefined in production

**Solution:**
1. Check Railway Dashboard → Variables
2. Ensure variables are set for correct environment (production)
3. Redeploy (env changes don't auto-deploy)
4. Verify in logs:
   ```javascript
   console.log('ENV CHECK:', process.env.MY_VAR ? '✅' : '❌')
   ```

---

### Pitfall 6: Build Succeeds, Deploy Fails

**Symptom:**
Build logs show success, but deploy logs show errors

**Common Causes:**
- Missing `startCommand` in railway.json
- Wrong working directory
- Missing environment variables
- Health check failing

**Debug:**
```bash
railway logs -f
# Look for actual error after "Starting Container"
```

---

### Pitfall 7: Excessive Bandwidth Usage

**Symptom:**
Railway usage dashboard shows high bandwidth

**Quick Fixes:**
1. Enable compression (80% reduction)
   ```bash
   npm install compression
   ```
2. Add cache headers
3. Paginate all list endpoints
4. Check for missing `limit` parameters

**Identify culprit:**
```bash
railway logs | grep "📊"
# Shows which endpoints are largest
```

---

## Performance Optimization Checklist

### Build Optimization

```javascript
// vite.config.js
export default defineConfig({
  build: {
    sourcemap: false, // Disable in production
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom']
        }
      }
    }
  }
})
```

### Server Optimization

```javascript
// Enable compression
app.use(compression({ level: 6 }))

// Limit JSON payload size
app.use(express.json({ limit: '10mb' }))

// Add request logging (only in development)
if (process.env.NODE_ENV === 'development') {
  app.use((req, res, next) => {
    console.log(`${req.method} ${req.path}`)
    next()
  })
}

// Cache static assets (1 year)
app.use(express.static('public', {
  maxAge: '365d',
  immutable: true
}))
```

### Client Optimization

```javascript
// Lazy load routes
const Queue = lazy(() => import('./Queue'))
const Settings = lazy(() => import('./Settings'))

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/queue" element={<Queue />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  )
}
```

---

## Security Best Practices

### 1. Environment Variables

**Never commit secrets:**
```gitignore
.env
.env.local
.env.production
```

**Use Railway's environment variables:**
- Set in Dashboard → Variables
- Access via `process.env.VAR_NAME`

---

### 2. Rate Limiting

**Protect against abuse:**

```bash
npm install express-rate-limit
```

```javascript
import rateLimit from 'express-rate-limit'

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  message: 'Too many requests, please try again later'
})

app.use('/api/', limiter)
```

---

### 3. Input Validation

**Validate all inputs:**

```javascript
app.post('/api/create', async (req, res) => {
  const { title, content } = req.body

  // Validate
  if (!title || typeof title !== 'string' || title.length > 200) {
    return res.status(400).json({ error: 'Invalid title' })
  }

  if (!content || typeof content !== 'string' || content.length > 10000) {
    return res.status(400).json({ error: 'Invalid content' })
  }

  // Process...
})
```

---

### 4. CORS Configuration

**Only allow your domains:**

```javascript
import cors from 'cors'

const allowedOrigins = process.env.NODE_ENV === 'production'
  ? ['https://your-app.railway.app']
  : ['http://localhost:3000']

app.use(cors({
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true)
    } else {
      callback(new Error('Not allowed by CORS'))
    }
  }
}))
```

---

## Documentation Standards

### Essential Files

**README.md:**
```markdown
# Your PoC Project

## Quick Start

## Local Development

## Deployment

## Environment Variables

## API Documentation
```

**CLAUDE.md** (for AI assistance):
```markdown
# Project Context

## Architecture

## Data Flow

## Key Implementation Details

## Important Rules
```

**docs/railway/deployment.md:**
- Track deployment issues
- Document solutions
- Include timestamps

---

## Cost Optimization Summary

### Day 1 Essentials (Free)

1. ✅ Enable compression (80% reduction)
2. ✅ Add cache headers (50% reduction)
3. ✅ Paginate all lists
4. ✅ Bind to 0.0.0.0
5. ✅ Enable public networking
6. ✅ Set usage alerts

**Expected Cost:** $2-3/month

---

### Week 1 Optimizations (Low effort)

7. ✅ Minimize response payloads
8. ✅ Lazy load images
9. ✅ Reduce volume size to 100MB
10. ✅ Add response size logging

**Expected Cost:** $1-2/month

---

### Month 1+ (As needed)

11. ✅ Implement IndexedDB caching
12. ✅ Add service worker
13. ✅ Consider CDN for assets

**Expected Cost:** < $1/month

---

## Final Checklist Before First Deploy

### Code

- [ ] `railway.json` configured
- [ ] `.node-version` specifies Node 22.13+
- [ ] Root `package.json` has `workspaces` array
- [ ] Server binds to `0.0.0.0`
- [ ] Health check endpoint exists
- [ ] Graceful shutdown handlers added
- [ ] Compression enabled
- [ ] Cache headers added
- [ ] Environment detection (dev/prod) works

### Configuration

- [ ] `.gitignore` excludes sensitive files
- [ ] `.dockerignore` excludes unnecessary files
- [ ] Test data in git (or upload strategy planned)
- [ ] Environment variables documented

### Railway

- [ ] Project created
- [ ] **Public networking enabled** ⚠️ Critical!
- [ ] Environment variables set
- [ ] Volume created (if needed)
- [ ] Usage alerts configured

### Testing

- [ ] Build succeeds locally
- [ ] App runs in production mode locally
- [ ] Bundle size checked (< 5MB)
- [ ] Health check responds
- [ ] Compression verified

---

## Project Management Scripts

The project includes helper scripts for managing Railway deployments:

### Enable Railway Deployments

```bash
./scripts/railway-enable.sh
```

This script will:
- Check if Railway CLI is installed
- Verify login status
- Confirm project is linked
- Guide you through enabling public networking
- Show current environment variables

### Disable Railway Deployments

```bash
./scripts/railway-disable.sh
```

This script provides options to:
1. **Remove the service** (preserves data/volumes, stops all deployments)
2. **Manual disconnect** (step-by-step guide to disable GitHub auto-deploy)

Both options preserve your:
- Project configuration
- Environment variables
- Volumes and data
- Deployment history

**Important:** The `railway down` command only deletes existing deployments but does NOT disconnect GitHub. To fully stop automatic deployments, you must manually disconnect the repository in the Railway Dashboard.

**Manual Disconnect Steps:**
1. Go to https://railway.app
2. Click on your project
3. Click on your service (e.g., poc-tumblr-queue-manager)
4. Go to the **Settings** tab (top navigation)
5. Find the **Source** section (first section in settings)
6. Under **Source Repo**, click the **Disconnect** button (to the right of your GitHub repository name)

**Alternative:** Scroll down in Settings and click **Pause Service** to stop all activity temporarily.

**Re-enabling later:** Simply run `./scripts/railway-enable.sh` and redeploy from Dashboard

---

## Quick Reference Commands

```bash
# Local development
npm run dev

# Local production test
npm run build
NODE_ENV=production npm start

# Railway management (use scripts)
./scripts/railway-enable.sh   # Enable deployments
./scripts/railway-disable.sh  # Disable deployments

# Railway CLI (manual)
railway login
railway init
railway link
railway logs -f
railway run bash
railway deployment list

# Check sizes
du -sh client/dist
du -sh /app/data

# Test endpoints
curl http://localhost:3001/health
curl https://your-app.railway.app/health

# Git workflow
git add .
git commit -m "feat: Add feature"
git push origin main
```

---

## Resources

**Railway Documentation:**
- https://docs.railway.app
- https://docs.railway.app/guides/volumes
- https://docs.railway.app/guides/optimize-usage

**Community:**
- Railway Discord: https://discord.gg/railway
- Railway GitHub: https://github.com/railwayapp

**Related Docs:**
- [Deployment Issues](./current/railway-deployment-issues-2025-10-04.md)
- [Optimization Recommendations](../optimization-recommendations.md)
- [Usage Summary](../railway-usage-summary.md)

---

## Conclusion

Following these practices will help you:
- ✅ Deploy successfully on first try
- ✅ Stay under $5/month budget
- ✅ Avoid common pitfalls
- ✅ Scale gracefully as usage grows

**Remember:**
1. Start with bandwidth optimization (compression + caching)
2. Enable public networking FIRST
3. Test locally before pushing
4. Monitor from day 1
5. Keep commits small and deployable

**Most Important:** Don't wait until your app is "done" to test deployment. Deploy early and often!

---

*Generated from real-world experience deploying Railway monorepo projects. Last updated: 2025-10-06*
