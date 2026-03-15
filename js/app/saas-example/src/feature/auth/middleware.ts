import { Effect, Option, Predicate } from 'effect'

import * as BetterAuth from '#@/feature/auth/better-auth.ts'
import * as HttpError from '#@/feature/http/error.ts'
import { factory } from '#@/feature/share/lib/hono/factory.ts'

export const prepare = factory.createMiddleware((c, next) => {
  const program = Effect.gen(function* () {
    const betterAuth = yield* BetterAuth.Service

    const session = yield* Effect.tryPromise(() =>
      betterAuth.api.getSession({
        headers: c.req.raw.headers,
      }),
    )

    if (Predicate.isNullish(session?.user) || Predicate.isNullish(session?.session)) {
      c.set('auth', Option.none())
    } else {
      c.set('auth', Option.some({ session: session.session, user: session.user }))
    }
    yield* Effect.tryPromise(next)
  }).pipe(
    Effect.catchTags({
      UnknownError: () => new HttpError.InternalServerError().makeResponseEffect(),
    }),
  )
  return c.var.runtime.runPromise(program)
})

export const unauthorized = factory.createMiddleware((c, next) => {
  const program = Effect.gen(function* () {
    if (Option.isNone(c.var.auth)) {
      return yield* Effect.fail(new HttpError.Unauthorized())
    }
    yield* Effect.tryPromise(next)
  }).pipe(
    Effect.catchTags({
      UnknownError: () => new HttpError.InternalServerError().makeResponseEffect(),
      'http/error/Unauthorized': (e) => e.makeResponseEffect(),
    }),
  )
  return c.var.runtime.runPromise(program)
})
