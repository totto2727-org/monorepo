import { Hono } from 'hono'
import { remixRenderer } from 'hono-remix-middleware'
import { logger } from 'hono/logger'

import { Document } from './ui/document.tsx'
import { Layout } from './ui/layout.tsx'
import { Todo } from './ui/todo.client.tsx'

const app = new Hono()

app
  .use(logger())
  .use(
    '*',
    remixRenderer({
      fetcher: (input) => Promise.resolve(app.fetch(input instanceof Request ? input : new Request(input))),
    }),
  )
  .get('/', (c) =>
    c.render(
      <Document title='Counter'>
        <Layout>
          <h1>Counter</h1>
        </Layout>
      </Document>,
    ),
  )
  .get('/todo', (c) =>
    c.render(
      <Document title='TODO'>
        <Layout>
          <h1>TODO</h1>
          <Todo />
        </Layout>
      </Document>,
    ),
  )

export default app
