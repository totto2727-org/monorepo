import { createMiddleware } from 'hono/factory'

import type * as Env from '../env.ts'
import * as Runtime from './server.ts'

export interface Variables {
  readonly runtime: Runtime.Runtime
}

export const middleware = createMiddleware<{
  Bindings: Env.Type
  Variables: Variables
}>(async (c, next) => {
  await using runtime = Runtime.make(c.env)
  c.set('runtime', runtime.instance)
  await next()
})
