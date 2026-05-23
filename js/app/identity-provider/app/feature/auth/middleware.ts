import { Effect } from 'effect'

import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as BetterAuth from './better-auth.ts'

export const authMiddleware = factory.createMiddleware(async (c, next) => {
  const auth = await c.var.runtime.runPromise(
    Effect.gen(function* () {
      return yield* BetterAuth.Service
    }),
  )
  c.set('auth', auth)
  await next()
})
