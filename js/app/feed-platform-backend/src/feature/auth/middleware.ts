import { Effect, Predicate, Schema } from 'effect'

import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as BetterAuth from './better-auth.ts'

const AuthUserPayload = Schema.Struct({
  email: Schema.String,
  id: Schema.String,
})

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- Better Auth session user is an external auth boundary.
const decodeAuthUserPayload = Schema.decodeUnknownEffect(AuthUserPayload)

export const authMiddleware = factory.createMiddleware((ctx, next) =>
  // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP middleware boundary executes request-scoped auth workflow.
  ctx.var.runtime.runPromise(
    Effect.gen(function* () {
      const auth = yield* BetterAuth.Service
      const result = yield* Effect.tryPromise({
        catch: (cause) => new Error(String(cause)),
        try: () => auth.api.getSession({ headers: ctx.req.raw.headers }),
      }).pipe(
        Effect.flatMap((value) =>
          Predicate.isNullish(value) ? Effect.succeed(null) : decodeAuthUserPayload(value.user),
        ),
        Effect.match({
          onFailure: () => null,
          onSuccess: (payload) => payload,
        }),
      )
      if (Predicate.isNullish(result)) {
        return ctx.json({ error: 'Unauthorized' }, 401, {
          'WWW-Authenticate': 'Session error="invalid_session"',
        })
      }
      ctx.set('user', { email: result.email, sub: result.id })
      return yield* Effect.promise(() => next())
    }),
  ),
)
