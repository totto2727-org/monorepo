import type { OptionalAuthVariables } from 'auth-helper'

import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as Runtime from './server.ts'

export interface Variables extends OptionalAuthVariables {
  readonly runtime: Runtime.Runtime
}

export const middleware = factory.createMiddleware(async (ctx, next) => {
  await using runtime = Runtime.make()
  ctx.set('runtime', runtime.instance)
  await next()
})
