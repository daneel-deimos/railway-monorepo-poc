# Railway Monorepo PoC

A monorepo setup proof-of-concept for starting up and deploying applications to Railway.

## Project Structure

```
railway-monorepo-poc/
├── client/          # React + Vite frontend (port 4444)
├── server/          # Express backend (port 3333)
├── docs/            # Documentation
└── railway.json     # Railway deployment config
```

## Quick Start

### Using this Template

If you created your repo from this template:

```bash
# 1. Clone your new repository
git clone <your-repo-url>
cd <your-repo-name>

# 2. Initialize from template (updates repo name references)
./scripts/init-from-template.sh

# 3. Install all dependencies (root + workspaces)
npm run init
```

### Prerequisites

- Node.js 22.13.0+ (specified in `.nvmrc`)
- npm 10.0.0+

### Local Installation

```bash
# Clone the repository
git clone <this repo URL>
cd railway-monorepo-poc

# Install all dependencies (root + workspaces)
npm run init
```

### Development

```bash
# Run both client and server concurrently
npm run dev

# Or run them separately:
npm run dev:client   # Client only (port 4444)
npm run dev:server   # Server only (port 3333)
```

Visit [http://localhost:4444](http://localhost:4444) to view the app.

### Testing the Connection

1. Click the "Test Server Connection" button on the homepage
2. Check the browser console for the logged server response
3. Check the server terminal for the logged API hit

### Production Build

```bash
# Build the client
npm run build

# Run in production mode (serves built client from server)
NODE_ENV=production npm start
```

## API Endpoints

- `GET /health` - Health check endpoint (required for Railway)
- `GET /api/hello` - Test endpoint that returns a JSON message

## Railway Deployment

This project is optimized for Railway deployment with production-ready features:

- ✅ Compression enabled (80% bandwidth reduction)
- ✅ Cache headers on API routes
- ✅ Health check endpoint
- ✅ 0.0.0.0 binding (container-ready)
- ✅ Graceful shutdown handlers
- ✅ Node version pinning (22.13.0)
- ✅ Monorepo workspace structure

### Automated Railway Setup

Deploy to Railway using our automated setup script:

```bash
npm run railway:setup
```

**What the script does:**
1. Checks prerequisites and installs Railway CLI
2. Authenticates with Railway (opens browser)
3. Creates and configures your Railway project
4. Sets environment variables automatically from `server/.env.example`
5. Prompts you to connect GitHub repository in Railway Dashboard
6. Prompts you to enable public networking (port 3333)
7. Monitors deployment and displays logs
8. Verifies deployment and provides your app URL

**Time to deploy:** ~5 minutes (2 manual steps required)

**For detailed instructions, see [Railway Installation Guide](docs/railway/railway-installation-guide.md)**

### Manual Deployment

If you prefer manual setup:

1. Install Railway CLI: `npm install --save-dev @railway/cli`
2. Authenticate: `npx railway login`
3. Create project: `npx railway init`
4. Set environment variables (see below)
5. Enable public networking in Railway Dashboard
6. Connect GitHub repository
7. Push to deploy: `git push origin main`

**See [Railway Installation Guide](docs/railway/railway-installation-guide.md) for step-by-step instructions.**

### Deployment Monitoring

```bash
# View deployment logs
npm run railway:logs

# Check deployment status
npx railway status

# Open Railway Dashboard
npx railway open
```

### Required Environment Variables

The setup script automatically configures these in Railway:

- `NODE_ENV=production`
- `RAILPACK_PACKAGES=nodejs@22.13.0`
- Custom variables from `server/.env.example`

### Additional Resources

- **Installation Guide**: [docs/railway/railway-installation-guide.md](docs/railway/railway-installation-guide.md)
- **Best Practices**: [docs/railway/railway-poc-best-practices.md](docs/railway/railway-poc-best-practices.md)
- **Railway Docs**: [docs.railway.app](https://docs.railway.app)

## Environment Variables

### Local Development

Create a `.env` file in the `server/` directory:

```bash
NODE_ENV=development
PORT=3333
```

### Railway Production

Environment variables are automatically set by `npm run railway:setup`.

To add custom variables, edit `server/.env.example` before running the setup script, or set them manually:

```bash
npx railway variables --set KEY=value
```

## Tech Stack

- **Frontend**: React 18, Vite 6
- **Backend**: Express 4, Node.js 22
- **Deployment**: Railway (with RAILPACK builder)
