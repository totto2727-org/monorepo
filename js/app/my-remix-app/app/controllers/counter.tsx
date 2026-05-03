import type { Context } from 'hono'

import { Counter } from '../ui/counter.tsx'
import { Layout } from '../ui/layout.tsx'
import { render } from '../utils/render.tsx'

export const counter = (c: Context) =>
  render(
    <Layout title='Counter'>
      <h1>Counter</h1>
      <Counter initial={0} />
    </Layout>,
    c.req.raw,
  )
