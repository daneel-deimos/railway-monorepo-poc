# Initial Setup Prompt

Use this prompt to recreate or set up a similar monorepo project structure.

---

## Prompt

Please create a basic monorepo scaffold with a client and server project using the following specifications:

**Framework & Tools:**
- Client: React with Vite
- Server: Express
- Package Manager: npm
- Node Version: 22.13.0 (as per Railway best practices)

**Ports:**
- Server: 3333
- Client: 4444

**Features:**
- On the client homepage, add a button that hits the `/api/hello` route on the Express server
- When the endpoint is hit, the server should console log a message
- The client should console log the response from the server

**Structure:**
Follow the Railway PoC best practices document structure with proper monorepo setup including workspaces, compression, health checks, and production-ready configuration.

**Additional Requirements:**
- Include a `.gitignore` file with standard exclusions
- Add an `init` script in the root `package.json` to install all workspace dependencies

---

## What This Creates

### Project Structure
```
railway-monorepo-poc/
├── .nvmrc                      # Node 22.13.0
├── .node-version               # Node 22.13.0
├── .gitignore                  # Comprehensive exclusions
├── .dockerignore               # Build optimization
├── railway.json                # Railway RAILPACK config
├── package.json                # Root with workspaces + scripts
├── README.md                   # Project documentation
├── docs/                       # Documentation folder
├── client/                     # React + Vite (port 4444)
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   └── src/
│       ├── main.jsx
│       ├── App.jsx
│       └── App.css
└── server/                     # Express (port 3333)
    ├── package.json
    └── index.js
```

### Key Features Included

**Railway-Ready Server (Express):**
- ✅ Compression middleware (80% bandwidth reduction)
- ✅ CORS enabled
- ✅ Health check endpoint: `/health`
- ✅ Test endpoint: `/api/hello` (with console logging)
- ✅ Binds to `0.0.0.0` (container-ready)
- ✅ Graceful shutdown handlers (SIGTERM/SIGINT)
- ✅ Cache headers on API routes
- ✅ Serves static client files in production
- ✅ Environment detection (development/production)

**Client (React + Vite):**
- ✅ Vite dev server on port 4444
- ✅ API proxy to server (port 3333)
- ✅ Test button that fetches `/api/hello`
- ✅ Console logs server response
- ✅ Visual feedback with success/error states
- ✅ Production build optimizations (vendor chunking, terser minification, no sourcemaps)

**Root Configuration:**
- ✅ npm workspaces: `["client", "server"]`
- ✅ ESM modules (`"type": "module"`)
- ✅ Node version enforcement (`engines` field)
- ✅ Comprehensive scripts (init, dev, build, start)

### Available Scripts

```bash
# Initialize project (first time setup)
npm run init

# Development
npm run dev              # Run both client + server concurrently
npm run dev:client       # Client only (port 4444)
npm run dev:server       # Server only (port 3333)

# Production
npm run build            # Build client for production
npm start                # Run server (serves built client)
```

### Quick Start

```bash
# After project creation:
npm run init
npm run dev

# Visit http://localhost:4444
# Click "Test Server Connection" button
# Check browser console for client logs
# Check terminal for server logs
```

### Railway Deployment

The project follows Railway PoC best practices from `docs/railway/railway-poc-best-practices.md`:

1. Enable public networking in Railway Dashboard
2. Set environment variables:
   - `NODE_ENV=production`
   - `RAILPACK_PACKAGES=nodejs@22.13.0`
3. Push to GitHub (Railway auto-deploys)

See [railway-poc-best-practices.md](railway/railway-poc-best-practices.md) for detailed deployment instructions.

---

## Customization Options

When using this prompt, you can customize:

1. **Ports**: Change server/client ports
2. **API Route**: Use different route name instead of `/api/hello`
3. **Console Message**: Customize the server log message
4. **Framework**: Swap React for Vue, Svelte, etc.
5. **Styling**: Modify the CSS or add a UI library

---

*Last updated: 2025-10-07*