import type { DB } from '#@/db/kysely.ts'
import type { Kysely } from 'kysely'

import { betterAuth } from 'better-auth'

export const makeBetterAuth = (db: Kysely<DB>) =>
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
    basePath: '/api',
    database: { db, type: 'sqlite' },
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
