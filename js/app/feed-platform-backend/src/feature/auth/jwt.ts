import type { AppJWTPayload } from 'auth-helper'
import { Context, Data, Effect, Layer, Predicate } from 'effect'
import { createRemoteJWKSet, jwtVerify } from 'jose'

export class JwtVerifyError extends Data.TaggedError('JwtVerifyError')<{
  readonly cause: unknown
}> {}

interface JwtService {
  readonly verify: (token: string) => Effect.Effect<AppJWTPayload, JwtVerifyError>
}

export const JwtService = Context.Service<JwtService>('JwtService')

const IDP_JWKS_URL = process.env.IDP_JWKS_URL ?? 'http://localhost:8787/api/v1/auth/jwks'
const IDP_BASE_URL = process.env.IDP_BASE_URL ?? 'http://localhost:8787'
const FEED_PLATFORM_AUDIENCE = process.env.FEED_PLATFORM_AUDIENCE ?? 'feed-platform-web'

const remoteJwkSet = createRemoteJWKSet(new URL(IDP_JWKS_URL))

export const liveLayer = Layer.succeed(JwtService, {
  verify: (token: string) =>
    Effect.tryPromise({
      catch: (cause) => new JwtVerifyError({ cause }),
      try: async () => {
        const { payload } = await jwtVerify(token, remoteJwkSet, {
          algorithms: ['ES256'],
          audience: FEED_PLATFORM_AUDIENCE,
          issuer: IDP_BASE_URL,
        })
        const { sub, iat, exp } = payload
        if (!Predicate.isString(sub)) {
          throw new TypeError('Missing sub claim')
        }
        if (!Predicate.isNumber(iat)) {
          throw new TypeError('Missing iat claim')
        }
        if (!Predicate.isNumber(exp)) {
          throw new TypeError('Missing exp claim')
        }
        return { exp, iat, sub }
      },
    }),
})
