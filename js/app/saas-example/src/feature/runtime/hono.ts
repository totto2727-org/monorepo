import { factory } from '#@/feature/share/lib/hono/factory.ts'

import type * as Runtime from './server.ts'

export const makeMiddleware = (makeRuntime: typeof Runtime.make) =>
  factory.createMiddleware(async (c, next) => {
    await using runtime = makeRuntime(c.env)
    c.set('runtime', runtime.instance)

    await next()
  })
