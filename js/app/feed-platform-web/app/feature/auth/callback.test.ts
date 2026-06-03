import { Effect, Layer } from 'effect'
import { HttpClient, HttpClientResponse } from 'effect/unstable/http'
import { Hono } from 'hono'
import { describe, expect, it } from 'vite-plus/test'

import { FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'
import { getAccessToken, getRefreshToken } from '#@/feature/auth/refresh-store.ts'
import { makeInMemory } from '#@/feature/db/kysely.ts'
import type { Instance as DBInstance } from '#@/feature/db/kysely.ts'
import type { Type as EnvType } from '#@/feature/env.ts'

import { handleAuthCallback } from './callback.ts'

const testEnv: EnvType = {
  BACKEND_BASE_URL: 'http://localhost:8789',
  BACKEND_RESOURCE: 'feed-platform-backend',
  DATABASE_AUTH_TOKEN: '',
  DATABASE_URL: ':memory:',
  IDP_BASE_URL: 'https://idp.example.com',
  OAUTH_CLIENT_ID: 'feed-platform-web',
  OAUTH_CLIENT_SECRET: '',
}

const makeHttpClientLayer = (response: Response) =>
  Layer.succeed(
    HttpClient.HttpClient,
    HttpClient.make((request) => Effect.succeed(HttpClientResponse.fromWeb(request, response))),
  )

const makeIdToken = (nonce: string): string => `header.${btoa(JSON.stringify({ nonce }))}.signature`

const validExpiresAt = 4_102_444_800_000

const makeApp = (
  db: DBInstance = makeInMemory(),
  httpClientLayer = makeHttpClientLayer(
    Response.json({ access_token: 'access-jwt-token', id_token: makeIdToken('mystate') }, { status: 200 }),
  ),
) =>
  new Hono().get('/auth/callback', (ctx) =>
    Effect.runPromise(handleAuthCallback(ctx, testEnv, db).pipe(Effect.provide(httpClientLayer))),
  )

const createRefreshSessionTable = async (db: DBInstance): Promise<void> => {
  await db.schema
    .createTable('oauth_refresh_session')
    .addColumn('session_token', 'text', (column) => column.primaryKey().notNull())
    .addColumn('access_token', 'text', (column) => column.notNull())
    .addColumn('refresh_token', 'text', (column) => column.notNull())
    .addColumn('expires_at', 'integer', (column) => column.notNull())
    .execute()
}

const createNonceTable = async (db: DBInstance): Promise<void> => {
  await db.schema
    .createTable('oauth_nonce')
    .addColumn('state', 'text', (column) => column.primaryKey().notNull())
    .addColumn('nonce', 'text', (column) => column.notNull())
    .addColumn('expires_at', 'integer', (column) => column.notNull())
    .execute()
}

const prepareNonce = async (db: DBInstance): Promise<void> => {
  await createNonceTable(db)
  await db.insertInto('oauthNonce').values({ expiresAt: validExpiresAt, nonce: 'mystate', state: 'mystate' }).execute()
}

const makeCookieHeader = (pairs: Record<string, string>) =>
  Object.entries(pairs)
    .map(([k, v]) => `${k}=${v}`)
    .join('; ')

describe('handleAuthCallback', () => {
  it('returns 403 when state mismatches', async () => {
    const app = makeApp()
    const res = await app.request('/auth/callback?code=abc&state=wrong', {
      headers: { cookie: makeCookieHeader({ oauth_state: 'correct', pkce_verifier: 'ver' }) },
    })
    expect(res.status).toBe(403)
  })

  it('redirects to /dashboard and sets feed-session on success', async () => {
    const db = makeInMemory()
    await prepareNonce(db)
    const app = makeApp(db)
    const res = await app.request('/auth/callback?code=authcode&state=mystate', {
      headers: { cookie: makeCookieHeader({ oauth_state: 'mystate', pkce_verifier: 'verifier123' }) },
    })
    expect(res.status).toBe(302)
    expect(res.headers.get('location')).toBe('/dashboard')
    const cookies = res.headers.getSetCookie()
    expect(cookies.some((cookie) => cookie.startsWith(`${FEED_SESSION_COOKIE}=header.`))).toBe(true)
  })

  it('stores refresh token in DB without setting a browser refresh cookie', async () => {
    const db = makeInMemory()
    await prepareNonce(db)
    await createRefreshSessionTable(db)
    const app = makeApp(
      db,
      makeHttpClientLayer(
        Response.json(
          {
            access_token: 'access-jwt-token',
            id_token: makeIdToken('mystate'),
            refresh_token: 'refresh-token-server-side',
          },
          { status: 200 },
        ),
      ),
    )
    const res = await app.request('/auth/callback?code=authcode&state=mystate', {
      headers: { cookie: makeCookieHeader({ oauth_state: 'mystate', pkce_verifier: 'verifier123' }) },
    })
    expect(res.status).toBe(302)
    const cookies = res.headers.getSetCookie()
    expect(cookies.some((cookie) => cookie.startsWith('feed-refresh='))).toBe(false)
    expect(await getAccessToken(db, makeIdToken('mystate'), 0)).toBe('access-jwt-token')
    expect(await getRefreshToken(db, makeIdToken('mystate'), 0)).toBe('refresh-token-server-side')
  })

  it('returns 401 when token endpoint returns non-200', async () => {
    const app = makeApp(makeInMemory(), makeHttpClientLayer(new Response(null, { status: 401 })))
    const res = await app.request('/auth/callback?code=authcode&state=mystate', {
      headers: { cookie: makeCookieHeader({ oauth_state: 'mystate', pkce_verifier: 'verifier123' }) },
    })
    expect(res.status).toBe(401)
  })

  it('returns 401 when access_token is missing from response', async () => {
    const app = makeApp(makeInMemory(), makeHttpClientLayer(Response.json({})))
    const res = await app.request('/auth/callback?code=authcode&state=mystate', {
      headers: { cookie: makeCookieHeader({ oauth_state: 'mystate', pkce_verifier: 'verifier123' }) },
    })
    expect(res.status).toBe(401)
  })
})
