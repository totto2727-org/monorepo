import { Button } from '@package/ui/components/ui/button'
import { createFileRoute, Link } from '@tanstack/react-router'
import { useState } from 'react'

const App = () => {
  const [count, setCount] = useState(0)

  return (
    <main>
      <h1>Hello, World!</h1>
      <p>Welcome to the Saas Example App.</p>
      <Link to='/'>Home</Link>

      <div>{count}</div>
      <Button onClick={() => setCount((c) => c + 1)}>Increment</Button>
    </main>
  )
}

export const Route = createFileRoute('/')({ component: App })
