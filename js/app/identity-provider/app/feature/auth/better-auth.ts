import { oauthProvider } from '@better-auth/oauth-provider'
import { passkey } from '@better-auth/passkey'
import { betterAuth } from 'better-auth'
import { jwt, magicLink } from 'better-auth/plugins'
import { Context, Effect, Layer } from 'effect'

import * as DB from '#@/feature/db/kysely.ts'
import * as EmailSender from '#@/feature/email/sender.ts'
import * as Env from '#@/feature/env.ts'
import * as HonoContext from '#@/feature/share/lib/hono/context.ts'

const makeInstance = (db: DB.Instance, env: Env.Type, emailSender: EmailSender.EmailSender, origin: string) =>
  betterAuth({
    account: {
      modelName: 'account',
    },
    basePath: '/api/v1/auth',
    baseURL: origin,
    database: { db, type: 'sqlite' },
    plugins: [
      passkey({
        origin,
        rpID: env.PASSKEY_RP_ID,
        rpName: 'identity-provider',
        schema: {
          passkey: {
            modelName: 'passkey',
          },
        },
      }),
      magicLink({
        sendMagicLink: ({ email, url }) =>
          Effect.runPromise(
            emailSender.send({
              subject: 'Login link',
              text: `Login here: ${url}`,
              to: email,
            }),
          ),
      }),
      oauthProvider({
        cachedTrustedClients: new Set(['feed-platform-web']),
        consentPage: '/app/oauth/consent',
        idTokenExpiresIn: 3600,
        loginPage: '/app/login',
        refreshTokenExpiresIn: 2_592_000,
        schema: {
          oauthAccessToken: {
            fields: {
              scopes: 'scope',
            },
            modelName: 'oauth_access_token',
          },
          oauthClient: {
            modelName: 'oauth_application',
          },
          oauthConsent: {
            fields: {
              scopes: 'scope',
            },
            modelName: 'oauth_consent',
          },
        },
        scopes: ['openid', 'profile', 'email', 'offline_access'],
        validAudiences: ['feed-platform-web', 'http://localhost:8789'],
      }),
      jwt({
        jwks: { keyPairConfig: { alg: 'ES256' } },
        schema: {
          jwks: {
            fields: {
              createdAt: 'createdAt',
              privateKey: 'privateKey',
              publicKey: 'publicKey',
            },
            modelName: 'jwks',
          },
        },
      }),
    ],
    secret: env.BETTER_AUTH_SECRET,
    session: {
      modelName: 'session',
      storeSessionInDatabase: true,
    },
    user: {
      modelName: 'user',
    },
    verification: {
      modelName: 'verification',
    },
  })

export type Instance = ReturnType<typeof makeInstance>

export const Service = Context.Service<Instance>('@app/identity-provider/feature/auth/better-auth/Service')

export const layer = Layer.effect(
  Service,
  Effect.gen(function* () {
    const db = yield* DB.Service
    const env = yield* Env.Service
    const emailSender = yield* EmailSender.Service
    const { origin } = new URL(HonoContext.get().req.url)
    return makeInstance(db, env, emailSender, origin)
  }),
)
