import { Effect, Predicate, Schema } from 'effect'

import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as BetterAuth from './better-auth.ts'

const AuthUserPayload = Schema.Struct({
  email: Schema.String,
  id: Schema.String,
})

const decodeAuthUserPayload = Schema.decodeEffect(AuthUserPayload)

const verifyUser = Effect.fn(function* (headers: Headers) {
  const auth = yield* BetterAuth.Service
  const session = yield* Effect.tryPromise(() => auth.api.getSession({ headers }))

  if (Predicate.isNullish(session)) {
    return null
  }
  return yield* decodeAuthUserPayload(session.user)
})

export const authMiddleware = factory.createMiddleware((ctx, next) => {
  const runtime = Effect.gen(function* () {
    ctx.set('user', yield verifyUser(ctx.req.raw.headers))

    yield* Effect.promise(() => next())
  })
  const catchedRuntime = runtime
  // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP middleware boundary executes the auth workflow once.
  return ctx.var.runtime.runPromise(catchedRuntime)
})
