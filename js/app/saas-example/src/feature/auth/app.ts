import { Effect } from 'effect'

import * as BetterAuth from '#@/feature/auth/better-auth.ts'
import { factory } from '#@/feature/share/lib/hono/factory.ts'

export const app = factory.createApp().on(['POST', 'GET'], '*', (c) =>
  Effect.gen(function* () {
    const betterAuth = yield* BetterAuth.Service
    return betterAuth.handler(c.req.raw)
  }).pipe(c.var.runtime.runPromise),
)
