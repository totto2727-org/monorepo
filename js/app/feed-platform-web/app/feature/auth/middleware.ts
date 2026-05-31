import type { AppJWTPayload } from 'auth-helper'
import { Effect, Predicate, Result, Schema } from 'effect'
import { getCookie } from 'hono/cookie'
import { createRemoteJWKSet, jwtVerify } from 'jose'

import { FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'
import { factory } from '#@/feature/share/lib/hono/factory.ts'

const AuthUserPayload = Schema.Struct({
  email: Schema.String,
  sub: Schema.String,
})

const decodeAuthUserPayload = Schema.decodeEffect(AuthUserPayload)

export const authMiddleware = factory.createMiddleware((ctx, next) =>
  // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP middleware boundary executes the auth workflow once.
  Effect.runPromise(
    Effect.gen(function* () {
      const token = getCookie(ctx, FEED_SESSION_COOKIE)

      if (Predicate.isNullish(token)) {
        ctx.set('user', null)
        yield* Effect.promise(() => next())
        return
      }

      const idpBaseUrl = ctx.env.IDP_BASE_URL
      const jwks = createRemoteJWKSet(new URL(`${idpBaseUrl}/api/v1/auth/jwks`))
      const verified = yield* Effect.result(Effect.tryPromise(() => jwtVerify<AppJWTPayload>(token, jwks)))
      if (Result.isFailure(verified)) {
        console.warn('[auth] JWT verification failed:', String(verified.failure))
        ctx.set('user', null)
        yield* Effect.promise(() => next())
        return
      }

      const decodedPayload = yield* Effect.result(decodeAuthUserPayload(verified.success.payload))
      if (Result.isFailure(decodedPayload)) {
        ctx.set('user', null)
      } else {
        const { email, sub } = decodedPayload.success
        ctx.set('user', { email, id: sub })
      }

      yield* Effect.promise(() => next())
    }),
  ),
)
