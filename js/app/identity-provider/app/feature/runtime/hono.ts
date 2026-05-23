import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as Runtime from './server.ts'

export const middleware = factory.createMiddleware(async (c, next) => {
  await using runtime = Runtime.make(c.env)
  c.set('runtime', runtime.instance)
  await next()
})
