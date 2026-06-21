import { Effect, Predicate, Schema } from 'effect'

import * as HonoContext from '#@/feature/share/lib/hono/context.ts'
import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as BetterAuth from './better-auth.ts'

const AuthUserPayload = Schema.Struct({
  email: Schema.String,
  id: Schema.String,
})

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- Better Auth session user is an external auth boundary.
const decodeAuthUserPayload = Schema.decodeUnknownEffect(AuthUserPayload)

const verifyUser = Effect.gen(function* () {
  const auth = yield* BetterAuth.Service
  const result = yield* Effect.tryPromise(() => auth.api.getSession({ headers: HonoContext.get().req.raw.headers }))
  if (Predicate.isNullish(result)) {
    return null
  }
  return yield* decodeAuthUserPayload(result.user)
})

export const authMiddleware = factory.createMiddleware((ctx, next) => {
  const runtime = Effect.gen(function* () {
    const user = yield* verifyUser
    if (Predicate.isNullish(user)) {
      return ctx.json({ error: 'Unauthorized' }, 401, {
        'WWW-Authenticate': 'Session error="invalid_session"',
      })
    }
    ctx.set('user', { email: user.email, sub: user.id })
    return yield* Effect.promise(() => next())
  })
  const catchedRuntime = runtime
  // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP middleware boundary executes request-scoped auth workflow.
  return ctx.var.runtime.runPromise(catchedRuntime)
})
