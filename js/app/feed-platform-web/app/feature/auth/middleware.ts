import { Effect, Predicate, Schema } from 'effect'

import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as BetterAuth from './better-auth.ts'

const AuthUserPayload = Schema.Struct({
  email: Schema.String,
  id: Schema.String,
})

const decodeAuthUserPayload = Schema.decodeEffect(AuthUserPayload)

export const authMiddleware = factory.createMiddleware((ctx, next) =>
  // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP middleware boundary executes the auth workflow once.
  ctx.var.runtime.runPromise(
    Effect.gen(function* () {
      const auth = yield* BetterAuth.Service
      const session = yield* Effect.tryPromise({
        catch: (cause) => new Error(String(cause)),
        try: () => auth.api.getSession({ headers: ctx.req.raw.headers }),
      }).pipe(
        Effect.flatMap((value) =>
          Predicate.isNullish(value) ? Effect.succeed(null) : decodeAuthUserPayload(value.user),
        ),
        Effect.match({
          onFailure: (failure) => {
            console.warn('[auth] Better Auth session validation failed:', String(failure))
            return null
          },
          onSuccess: (payload) => payload,
        }),
      )

      ctx.set('user', Predicate.isNullish(session) ? null : { email: session.email, sub: session.id })

      yield* Effect.promise(() => next())
    }),
  ),
)
