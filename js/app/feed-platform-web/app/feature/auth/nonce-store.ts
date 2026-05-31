import { Predicate } from 'effect'

import type { Instance } from '#@/feature/db/kysely.ts'

const NONCE_TTL_MS = 10 * 60 * 1000

export const storeNonce = async (db: Instance, state: string, nonce: string, now: number): Promise<void> => {
  await db
    .insertInto('oauth_nonce')
    .values({ expires_at: now + NONCE_TTL_MS, nonce, state })
    .execute()
}

export const verifyAndDeleteNonce = async (db: Instance, state: string, nonce: string): Promise<boolean> => {
  const row = await db.selectFrom('oauth_nonce').select('nonce').where('state', '=', state).executeTakeFirst()
  await db.deleteFrom('oauth_nonce').where('state', '=', state).execute()
  return Predicate.isNotNullish(row) && row.nonce === nonce
}

export const cleanupExpiredNonces = async (db: Instance, now: number): Promise<void> => {
  await db.deleteFrom('oauth_nonce').where('expires_at', '<', now).execute()
}
