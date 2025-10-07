import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],

  // Development server configuration
  server: {
    host: true,
    port: 4444,
    // API proxy for local development
    proxy: {
      '/api': {
        target: 'http://localhost:3333',
        changeOrigin: true
      }
    }
  },

  // Build optimizations for Railway
  build: {
    outDir: 'dist',
    sourcemap: false, // Disable in production to save space
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: {
          // Split vendor code for better caching
          vendor: ['react', 'react-dom']
        }
      }
    }
  }
})
