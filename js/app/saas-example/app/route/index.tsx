import { createFileRoute } from '@tanstack/react-router'
import { useEffect, useState } from 'react'

const Index = () => {
  const [count, setCount] = useState(0)
  const increase = () => setCount((c) => c + 1)

  useEffect(() => {
    console.log(count)
  }, [count])

  return (
    <main>
      <h2>{count}</h2>
      <button type='button' onClick={increase}>
        Increase
      </button>
    </main>
  )
}

export const Route = createFileRoute('/')({
  component: Index,
  head: () => ({
    meta: [{ title: 'Count app' }, { content: 'Count app', name: 'description' }],
  }),
})
