import { Predicate } from 'effect'

import type { Instance } from '#@/feature/db/kysely.ts'

const NONCE_TTL_MS = 10 * 60 * 1000

export const storeNonce = async (db: Instance, state: string, nonce: string): Promise<void> => {
  // oxlint-disable-next-line rules/no-js-date -- DB timestamp boundary
  const expiresAt = Date.now() + NONCE_TTL_MS
  await db.insertInto('oauth_nonce').values({ expires_at: expiresAt, nonce, state }).execute()
}

export const verifyAndDeleteNonce = async (db: Instance, state: string, nonce: string): Promise<boolean> => {
  const row = await db.selectFrom('oauth_nonce').select('nonce').where('state', '=', state).executeTakeFirst()

  await db.deleteFrom('oauth_nonce').where('state', '=', state).execute()

  // oxlint-disable-next-line rules/prefer-is-nullish -- row from Kysely is OauthNonceTable | undefined, intentional distinction
  return !Predicate.isUndefined(row) && row.nonce === nonce
}

export const cleanupExpiredNonces = async (db: Instance): Promise<void> => {
  // oxlint-disable-next-line rules/no-js-date -- DB timestamp boundary, Effect DateTime not applicable
  await db.deleteFrom('oauth_nonce').where('expires_at', '<', Date.now()).execute()
}
