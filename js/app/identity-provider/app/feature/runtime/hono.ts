import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as Runtime from './server.ts'

export const middleware = factory.createMiddleware(async (ctx, next) => {
  await using runtime = Runtime.make()
  ctx.set('runtime', runtime.instance)
  await next()
})
