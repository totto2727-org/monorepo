import { Hono } from 'hono'
import { logger } from 'hono/logger'

import { remixRenderer } from './middleware/renderer.tsx'
import { Counter } from './ui/counter.tsx'
import { Todo } from './ui/todo.tsx'

const app = new Hono()

app
  .use(logger())
  .use('*', remixRenderer((request) => app.fetch(request)))
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
