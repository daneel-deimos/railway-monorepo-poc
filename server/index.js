import 'dotenv/config'
import express from 'express'
import compression from 'compression'
import cors from 'cors'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const app = express()
const PORT = process.env.PORT || 3333
const NODE_ENV = process.env.NODE_ENV || 'development'

// 1. COMPRESSION (Essential for cost savings - 60-80% bandwidth reduction)
app.use(compression({
  level: 6,
  threshold: 1024 // Only compress responses > 1KB
}))

// 2. CORS (allow frontend to communicate)
app.use(cors())

// 3. JSON parsing
app.use(express.json({ limit: '10mb' }))

// 4. Health check BEFORE other routes (Railway needs this)
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    env: NODE_ENV
  })
})

// 5. API routes
app.get('/api/hello', (req, res) => {
  const timestamp = new Date().toISOString()

  // Console log when endpoint is hit
  console.log(`[API] /api/hello endpoint hit at ${timestamp}`)

  // Set cache headers (5 minute cache)
  res.set('Cache-Control', 'public, max-age=300')

  // Send response
  res.json({
    message: 'Hello from server!',
    timestamp
  })
})

// 6. Static files (production only)
if (NODE_ENV === 'production') {
  const clientBuildPath = path.join(__dirname, '..', 'client', 'dist')
  app.use(express.static(clientBuildPath))

  // SPA fallback
  app.get('*', (req, res) => {
    res.sendFile(path.join(clientBuildPath, 'index.html'))
  })
}

// 7. Bind to 0.0.0.0 (NOT localhost - critical for Railway)
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on http://0.0.0.0:${PORT}`)
  console.log(`📦 Environment: ${NODE_ENV}`)
  console.log('✅ Ready to accept connections')
})

// 8. Graceful shutdown (Railway sends SIGTERM)
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
