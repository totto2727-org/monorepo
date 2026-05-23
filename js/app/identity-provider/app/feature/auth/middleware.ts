import { Effect } from 'effect'
import { createMiddleware } from 'hono/factory'

import type * as Env from '../env.ts'
import type * as Runtime from '../runtime/server.ts'
import * as BetterAuth from './better-auth.ts'

export const authMiddleware = createMiddleware<{
  Bindings: Env.Type
  Variables: {
    readonly runtime: Runtime.Runtime
    readonly auth: BetterAuth.Instance
  }
}>(async (c, next) => {
  const runtime = c.get('runtime')
  const auth = await runtime.runPromise(
    Effect.gen(function* () {
      return yield* BetterAuth.Service
    }),
  )
  c.set('auth', auth)
  await next()
})
