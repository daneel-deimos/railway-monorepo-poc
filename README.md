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

### Prerequisites

- Node.js 22.13.0+ (specified in `.nvmrc`)
- npm 10.0.0+

### Installation

```bash
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

This project follows Railway best practices:

- ✅ Compression enabled (80% bandwidth reduction)
- ✅ Cache headers on API routes
- ✅ Health check endpoint
- ✅ 0.0.0.0 binding (container-ready)
- ✅ Graceful shutdown handlers
- ✅ Node version pinning (22.13.0)
- ✅ Monorepo workspace structure

See [docs/railway/railway-poc-best-practices.md](docs/railway/railway-poc-best-practices.md) for detailed deployment instructions.

## Environment Variables

### Local Development

Create a `.env` file in the `server/` directory:

```bash
NODE_ENV=development
PORT=3333
```

### Railway Production

Set in Railway Dashboard:
- `NODE_ENV=production`
- `RAILPACK_PACKAGES=nodejs@22.13.0`

## Tech Stack

- **Frontend**: React 18, Vite 6
- **Backend**: Express 4, Node.js 22
- **Deployment**: Railway (with RAILPACK builder)
