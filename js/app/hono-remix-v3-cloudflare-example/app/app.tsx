import { Hono } from 'hono'
import { remixRenderer } from 'hono-remix-middleware'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import { PageOrFrame } from './ui/content-layout.tsx'
import { Todo } from './ui/todo.client.tsx'
import { UiShowcase } from './ui/ui-showcase.client.tsx'

const app = new Hono()

app
  .use(logger())
  .use(contextStorage())
  .use(
    '*',
    remixRenderer({
      fetcher: (input) => Promise.resolve(app.fetch(input instanceof Request ? input : new Request(input))),
    }),
  )
  .get('/', (c) =>
    c.render(
      <PageOrFrame title='Counter'>
        <h1>Counter</h1>
      </PageOrFrame>,
    ),
  )
  .get('/todo', (c) =>
    c.render(
      <PageOrFrame title='TODO'>
        <h1>TODO</h1>
        <Todo />
      </PageOrFrame>,
    ),
  )
  .get('/ui', (c) =>
    c.render(
      <PageOrFrame title='UI Components'>
        <UiShowcase />
      </PageOrFrame>,
    ),
  )

export default app
