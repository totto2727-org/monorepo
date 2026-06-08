import { betterAuth } from 'better-auth'
import { bearer, genericOAuth } from 'better-auth/plugins'
import { Context, Effect, Layer } from 'effect'

import * as Env from '#@/feature/env.ts'

const makeInstance = (env: Env.Type) =>
  betterAuth({
    account: {
      storeAccountCookie: true,
      storeStateStrategy: 'cookie',
    },
    basePath: '/api/v1/auth',
    baseURL: env.WEB_BASE_URL,
    plugins: [
      genericOAuth({
        config: [
          {
            authorizationUrl: `${env.IDP_BASE_URL}/api/v1/auth/oauth2/authorize`,
            clientId: env.OAUTH_CLIENT_ID,
            clientSecret: env.OAUTH_CLIENT_SECRET,
            issuer: `${env.IDP_BASE_URL}/api/v1/auth`,
            pkce: true,
            providerId: 'identity-provider',
            requireIssuerValidation: true,
            scopes: ['openid', 'profile', 'email'],
            tokenUrl: `${env.IDP_BASE_URL}/api/v1/auth/oauth2/token`,
            userInfoUrl: `${env.IDP_BASE_URL}/api/v1/auth/oauth2/userinfo`,
          },
        ],
      }),
      bearer(),
    ],
    secret: env.BETTER_AUTH_SECRET,
    session: {
      cookieCache: {
        enabled: true,
        maxAge: 5 * 60,
        strategy: 'jwe',
      },
    },
  })

export type Instance = ReturnType<typeof makeInstance>

export const Service = Context.Service<Instance>('@app/feed-platform-web/feature/auth/better-auth/Service')

export const layer = Layer.effect(
  Service,
  Effect.gen(function* () {
    const env = yield* Env.Service
    return makeInstance(env)
  }),
)
