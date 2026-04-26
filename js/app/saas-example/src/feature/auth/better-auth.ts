import { betterAuth } from 'better-auth'
import { Context, Effect, Layer } from 'effect'

import * as DB from '#@/feature/db/kysely.ts'
import * as Env from '#@/feature/env.ts'

const makeInstance = (db: DB.Instance, env: Env.BetterAuth) =>
  betterAuth({
    account: {
      fields: {
        accessToken: 'access_token',
        accessTokenExpiresAt: 'access_token_expires_at',
        accountId: 'account_id',
        createdAt: 'created_at',
        idToken: 'id_token',
        providerId: 'provider_id',
        refreshToken: 'refresh_token',
        refreshTokenExpiresAt: 'refresh_token_expires_at',
        updatedAt: 'updated_at',
      },
      modelName: 'account',
    },
    basePath: '/api/v1/auth',
    baseURL: env.BETTER_AUTH_URL,
    database: { db, type: 'sqlite' },
    secret: env.BETTER_AUTH_SECRET,
    session: {
      fields: {
        createdAt: 'created_at',
        expiresAt: 'expires_at',
        ipAddress: 'ip_address',
        updatedAt: 'updated_at',
        userAgent: 'user_agent',
        userId: 'user_id',
      },
      modelName: 'session',
    },
    user: {
      fields: {
        createdAt: 'created_at',
        emailVerified: 'email_verified',
        updatedAt: 'updated_at',
      },
      modelName: 'user',
    },
    verification: {
      fields: {
        createdAt: 'created_at',
        expiresAt: 'expires_at',
        updatedAt: 'updated_at',
      },
      modelName: 'verification',
    },
  })

export type Instance = ReturnType<typeof makeInstance>

export const Service = Context.Service<Instance>('@app/saas-example/feature/auth/better-auth/Service')

export const layer = Layer.effect(
  Service,
  Effect.gen(function* () {
    const db = yield* DB.Service
    const env = yield* Env.Service
    return makeInstance(db, env)
  }),
)
