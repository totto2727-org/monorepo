import { Button } from '@package/ui/components/ui/button'
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
      <h1 className='text-4xl'>{count}</h1>
      <Button
        render={
          // oxlint-disable-next-line anchor-is-valid,anchor-has-content
          <a />
        }
        nativeButton={false}
        onClick={increase}
      >
        Increase
      </Button>
    </main>
  )
}

export const Route = createFileRoute('/')({
  component: Index,
  head: () => ({
    meta: [{ title: 'Count app' }, { content: 'Count app', name: 'description' }],
  }),
})
