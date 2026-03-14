import { Hono } from 'hono'

import type { DisposableRuntime } from './feature/di/server.ts'
import type { Env } from './feature/hono/context.ts'

export const makeHono = (Runtime: typeof DisposableRuntime) => {
  const app = new Hono<Env>().use('*', async (c, next) => {
    await using runtime = new Runtime(c.env)
    c.set('runtime', runtime.instance)

    await next()
  })
  return app
}
