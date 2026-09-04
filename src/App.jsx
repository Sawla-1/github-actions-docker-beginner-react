import { useState } from 'react'
import './App.css'

function App() 
  const [click, setClicks] = useState(0);

  return (
    <main className="card">
      <h1>Hello, Docker! 🐳</h1>
      <p>This tiny React app is packed in a Docker image and checked by GitHub Actions.</p>

      <button onClick={() => setClicks(clicks + 1)}>Click me</button>
      <p>Clicks: {clicks}</p>
    </main>
  )
}

export default App
