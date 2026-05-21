import { oauthProvider } from '@better-auth/oauth-provider'
import { passkey } from '@better-auth/passkey'
import { betterAuth } from 'better-auth'
import { jwt, magicLink } from 'better-auth/plugins'
import { Context, Effect, Layer } from 'effect'

import * as DB from '#@/feature/db/kysely.ts'
import * as EmailSender from '#@/feature/email/sender.ts'
import * as Env from '#@/feature/env.ts'

const effectRunPromise = Effect.runPromise

const makeInstance = (db: DB.Instance, env: Env.Type, emailSender: EmailSender.EmailSender) =>
  betterAuth({
    account: {
      modelName: 'account',
    },
    basePath: '/api/v1/auth',
    baseURL: env.BETTER_AUTH_URL,
    database: { db, type: 'sqlite' },
    plugins: [
      passkey({
        origin: env.BASE_URL,
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
          effectRunPromise(
            emailSender.send({
              subject: 'Login link',
              text: `Login here: ${url}`,
              to: email,
            }),
          ),
      }),
      oauthProvider({
        cachedTrustedClients: new Set(['feed-platform-web']),
        consentPage: '/oauth/consent',
        loginPage: '/login',
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
        scopes: ['openid', 'profile', 'email'],
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
    return makeInstance(db, env, emailSender)
  }),
)
