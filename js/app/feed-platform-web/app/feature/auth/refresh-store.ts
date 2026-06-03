import { Predicate } from 'effect'

import type { Instance } from '#@/feature/db/kysely.ts'

const REFRESH_SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000

export const deleteRefreshToken = async (db: Instance, sessionToken: string): Promise<void> => {
  await db.deleteFrom('oauthRefreshSession').where('sessionToken', '=', sessionToken).execute()
}

export const getRefreshToken = async (db: Instance, sessionToken: string, now: number): Promise<string | null> => {
  const row = await db
    .selectFrom('oauthRefreshSession')
    .select(['expiresAt', 'refreshToken'])
    .where('sessionToken', '=', sessionToken)
    .executeTakeFirst()
  if (Predicate.isNullish(row)) {
    return null
  }
  if (row.expiresAt < now) {
    await deleteRefreshToken(db, sessionToken)
    return null
  }
  return row.refreshToken
}

export const getAccessToken = async (db: Instance, sessionToken: string, now: number): Promise<string | null> => {
  const row = await db
    .selectFrom('oauthRefreshSession')
    .select(['accessToken', 'expiresAt'])
    .where('sessionToken', '=', sessionToken)
    .executeTakeFirst()
  if (Predicate.isNullish(row)) {
    return null
  }
  if (row.expiresAt < now) {
    await deleteRefreshToken(db, sessionToken)
    return null
  }
  return row.accessToken
}

export const storeRefreshToken = async (
  db: Instance,
  sessionToken: string,
  refreshToken: string,
  accessToken: string,
  now: number,
): Promise<void> => {
  await db
    .insertInto('oauthRefreshSession')
    .values({ accessToken, expiresAt: now + REFRESH_SESSION_TTL_MS, refreshToken, sessionToken })
    .onConflict((oc) =>
      oc.column('sessionToken').doUpdateSet({ accessToken, expiresAt: now + REFRESH_SESSION_TTL_MS, refreshToken }),
    )
    .execute()
}

export const replaceRefreshToken = async (
  db: Instance,
  previousSessionToken: string,
  nextSessionToken: string,
  refreshToken: string,
  accessToken: string,
  now: number,
): Promise<void> => {
  await db.deleteFrom('oauthRefreshSession').where('sessionToken', '=', previousSessionToken).execute()
  await storeRefreshToken(db, nextSessionToken, refreshToken, accessToken, now)
}
