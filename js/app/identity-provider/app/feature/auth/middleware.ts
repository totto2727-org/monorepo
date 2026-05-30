import { Effect } from 'effect'

import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as BetterAuth from './better-auth.ts'

export const authMiddleware = factory.createMiddleware(async (ctx, next) => {
  // oxlint-disable-next-line rules/no-effect-runtime-run -- Hono middleware boundary reads request runtime service for downstream handlers.
  const auth = await ctx.var.runtime.runPromise(
    Effect.gen(function* () {
      return yield* BetterAuth.Service
    }),
  )
  ctx.set('auth', auth)
  await next()
})
