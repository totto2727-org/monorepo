import { serveStatic } from '@hono/node-server/serve-static'
import { Hono } from 'hono'
import { logger } from 'hono/logger'
import { remixRenderer } from 'hono-remix-middleware'
import type { RemixNode } from 'remix/ui'

import { Counter } from './ui/counter.client.tsx'
import { Layout } from './ui/layout.tsx'
import { Todo } from './ui/todo.client.tsx'

declare module 'hono' {
  interface ContextRenderer {
    (content: RemixNode, props?: { title?: string }): Response
  }
}

const app = new Hono()

app
  .use(logger())
  .use('/assets/*', serveStatic({ root: './dist/client' }))
  .use(
    '*',
    remixRenderer<{ title?: string }>({
      fetcher: (request) => app.fetch(request),
      wrap: (content, { title }) => <Layout title={title}>{content}</Layout>,
    }),
  )
  .get('/', (c) =>
    c.render(
      <>
        <h1>Counter</h1>
        <Counter initial={0} />
      </>,
      { title: 'Counter' },
    ),
  )
  .get('/todo', (c) =>
    c.render(
      <>
        <h1>TODO</h1>
        <Todo />
      </>,
      { title: 'TODO' },
    ),
  )

export default app
