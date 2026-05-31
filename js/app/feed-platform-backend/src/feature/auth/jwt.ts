import { Context, Data, Effect, Layer, Predicate } from 'effect'
import { createRemoteJWKSet, jwtVerify } from 'jose'

import type { AppJWTPayload } from '#@/feature/auth/jwt-payload.ts'
import * as Env from '#@/feature/env.ts'

export class JwtVerifyError extends Data.TaggedError('JwtVerifyError')<{
  readonly cause: unknown
}> {}

export interface Type {
  readonly verify: (token: string) => Effect.Effect<AppJWTPayload, JwtVerifyError>
}

export const Service = Context.Service<Type>('@app/feed-platform-backend/feature/auth/jwt/Service')

const remoteJwkSets = new Map<string, ReturnType<typeof createRemoteJWKSet>>()

const makeRemoteJwkSet = (url: string) => {
  const remoteJwkSet = remoteJwkSets.get(url)
  if (Predicate.isNotNullish(remoteJwkSet)) {
    return remoteJwkSet
  }
  const nextRemoteJwkSet = createRemoteJWKSet(new URL(url))
  remoteJwkSets.set(url, nextRemoteJwkSet)
  return nextRemoteJwkSet
}

export const layer = Layer.effect(
  Service,
  Effect.gen(function* () {
    const env = yield* Env.Service
    const remoteJwkSet = makeRemoteJwkSet(env.IDP_JWKS_URL)

    return {
      verify: (token: string) =>
        Effect.tryPromise({
          catch: (cause) => new JwtVerifyError({ cause }),
          try: async () => {
            const { payload } = await jwtVerify(token, remoteJwkSet, {
              algorithms: ['ES256'],
              audience: env.FEED_PLATFORM_AUDIENCE,
              issuer: env.IDP_BASE_URL,
            })
            const { sub, email, iat, exp } = payload as {
              sub?: unknown
              email?: unknown
              iat?: unknown
              exp?: unknown
            }
            if (!Predicate.isString(sub)) {
              throw new TypeError('Missing sub claim')
            }
            if (!Predicate.isString(email)) {
              throw new TypeError('Missing email claim')
            }
            return {
              email,
              sub,
              ...(Predicate.isNumber(iat) ? { iat } : {}),
              ...(Predicate.isNumber(exp) ? { exp } : {}),
            }
          },
        }),
    }
  }),
)
