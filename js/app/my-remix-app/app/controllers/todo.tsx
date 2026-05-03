import type { Context } from 'hono'

import { Layout } from '../ui/layout.tsx'
import { Todo } from '../ui/todo.tsx'
import { render } from '../utils/render.tsx'

export const todo = (c: Context) =>
  render(
    <Layout title='TODO'>
      <h1>TODO</h1>
      <Todo />
    </Layout>,
    c.req.raw,
  )
