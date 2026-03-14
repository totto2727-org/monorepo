import type { Kysely } from 'kysely'

import * as DB from '#@/feature/db/kysely.ts'
import * as Env from '#@/feature/env.ts'
import { betterAuth } from 'better-auth'
import { Effect, Layer, ServiceMap } from 'effect'

const makeInstance = (db: Kysely<DB.DB>, env: { BETTER_AUTH_URL: string; BETTER_AUTH_SECRET: string }) =>
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
    basePath: '/api/auth',
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

export const Service = ServiceMap.Service<Instance>('@app/saas-example/feature/auth/better-auth/Service')

export const layer = Layer.effect(
  Service,
  Effect.gen(function* () {
    const db = yield* DB.Service
    const env = yield* Env.Service
    return makeInstance(db, env)
  }),
)
