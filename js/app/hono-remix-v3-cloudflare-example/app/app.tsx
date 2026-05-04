import { Hono } from 'hono'
import { remixRenderer } from 'hono-remix-middleware'
import { logger } from 'hono/logger'
import type { RemixNode } from 'remix/ui'

import { Counter } from './ui/counter.client.tsx'
import { Layout } from './ui/layout.tsx'
import { Todo } from './ui/todo.client.tsx'

interface RenderProps {
  title?: string
}

declare module 'hono' {
  // Interface (not type alias) is required so this augmentation merges
  // with hono's own `ContextRenderer`. A `marker` member keeps the
  // "prefer-function-type" lint rule from collapsing the call signature
  // into a type alias — the marker is never read.
  interface ContextRenderer {
    (content: RemixNode, props?: RenderProps): Response
    readonly marker?: never
  }
}

const app = new Hono()

app
  .use(logger())
  .use(
    '*',
    remixRenderer<RenderProps>({
      fetcher: (input) => Promise.resolve(app.fetch(input instanceof Request ? input : new Request(input))),
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
