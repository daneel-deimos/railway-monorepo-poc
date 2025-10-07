import { useState } from 'react'

function App() {
  const [response, setResponse] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const handleTestServer = async () => {
    setLoading(true)
    setError(null)

    try {
      const res = await fetch('/api/hello')

      if (!res.ok) {
        throw new Error(`HTTP error! status: ${res.status}`)
      }

      const data = await res.json()

      // Console log the server response
      console.log('Server response:', data)

      setResponse(data)
    } catch (err) {
      console.error('Error fetching from server:', err)
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="app">
      <h1>Railway Monorepo PoC</h1>
      <p>Test the server connection</p>

      <button
        onClick={handleTestServer}
        disabled={loading}
        className="test-button"
      >
        {loading ? 'Testing...' : 'Test Server Connection'}
      </button>

      {response && (
        <div className="response-box success">
          <h3>Success! ✅</h3>
          <p><strong>Message:</strong> {response.message}</p>
          <p><strong>Timestamp:</strong> {response.timestamp}</p>
          <p className="hint">Check the browser console for the logged response</p>
        </div>
      )}

      {error && (
        <div className="response-box error">
          <h3>Error ❌</h3>
          <p>{error}</p>
        </div>
      )}
    </div>
  )
}

export default App
