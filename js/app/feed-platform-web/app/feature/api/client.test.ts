import { Effect, Layer, Predicate } from 'effect'
import { FetchHttpClient } from 'effect/unstable/http'
import { Hono } from 'hono'
import { contextStorage } from 'hono/context-storage'
import { afterEach, describe, expect, it, vi } from 'vite-plus/test'

import { FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'
import * as DB from '#@/feature/db/kysely.ts'
import * as Env from '#@/feature/env.ts'
import type { Env as HonoEnv } from '#@/feature/share/lib/hono/context.ts'

import { BackendClient, liveLayer } from './client.ts'

const testEnv = {
  BACKEND_BASE_URL: 'http://localhost:8789',
  BACKEND_RESOURCE: 'feed-platform-backend',
  DATABASE_AUTH_TOKEN: '',
  DATABASE_URL: ':memory:',
  IDP_BASE_URL: 'https://idp.example.com',
  OAUTH_CLIENT_ID: 'feed-platform-web',
  OAUTH_CLIENT_SECRET: 'dev-secret',
} satisfies Env.Type

const createRefreshSessionTable = async (db: DB.Instance): Promise<void> => {
  await db.schema
    .createTable('oauth_refresh_session')
    .addColumn('session_token', 'text', (column) => column.primaryKey().notNull())
    .addColumn('access_token', 'text', (column) => column.notNull())
    .addColumn('refresh_token', 'text', (column) => column.notNull())
    .addColumn('expires_at', 'integer', (column) => column.notNull())
    .execute()
}

const makeTestLayer = (db: DB.Instance) =>
  liveLayer.pipe(
    Layer.provideMerge(FetchHttpClient.layer),
    Layer.provideMerge(Layer.succeed(DB.Service, db)),
    Layer.provide(Env.makeLayer(testEnv)),
  )

const successResponse = () =>
  Promise.resolve(Response.json({ email: 'user@example.com', sub: 'user-1' }, { status: 200 }))

const validExpiresAt = 4_102_444_800_000

afterEach(() => {
  vi.restoreAllMocks()
  vi.unstubAllGlobals()
})

const requestCallMe = (db: DB.Instance, cookie?: string) => {
  const app = new Hono<HonoEnv>().use(contextStorage()).get('/test', async (ctx) =>
    ctx.json(
      await Effect.runPromise(
        Effect.provide(
          Effect.gen(function* () {
            const client = yield* BackendClient
            return yield* client.callMe().pipe(
              Effect.match({
                onFailure: () => ({ ok: false }),
                onSuccess: (data) => ({ data, ok: true }),
              }),
            )
          }),
          makeTestLayer(db),
        ),
      ),
    ),
  )
  return app.request('/test', Predicate.isNullish(cookie) ? undefined : { headers: { cookie } }, testEnv)
}

const requestCallMeWithAccessToken = () => {
  const db = DB.makeInMemory()
  const app = new Hono<HonoEnv>().use(contextStorage()).get('/test', async (ctx) =>
    ctx.json(
      await Effect.runPromise(
        Effect.provide(
          Effect.gen(function* () {
            const client = yield* BackendClient
            return yield* client.callMeWithAccessToken('test-jwt').pipe(
              Effect.match({
                onFailure: () => ({ ok: false }),
                onSuccess: (data) => ({ data, ok: true }),
              }),
            )
          }),
          makeTestLayer(db),
        ),
      ),
    ),
  )
  return app.request('/test', undefined, testEnv)
}

describe('BackendClient.callMe', () => {
  it('reads authorization from Hono context and supports refresh-token retry calls', async () => {
    const db = DB.makeInMemory()
    await createRefreshSessionTable(db)
    await db
      .insertInto('oauthRefreshSession')
      .values({
        accessToken: 'stored-access-jwt',
        expiresAt: validExpiresAt,
        refreshToken: 'refresh-token',
        sessionToken: 'id-token-session',
      })
      .execute()
    const mockFetch = vi
      .fn<(input: RequestInfo | URL, init?: RequestInit) => Promise<Response>>()
      .mockImplementationOnce(successResponse)
      .mockImplementationOnce(successResponse)
      .mockImplementationOnce(() => Promise.resolve(new Response(null, { status: 401 })))
    vi.stubGlobal('fetch', mockFetch)

    const cookieResponse = await requestCallMe(db, `${FEED_SESSION_COOKIE}=id-token-session`)
    const accessTokenResponse = await requestCallMeWithAccessToken()
    const missingCookieResponse = await requestCallMe(db)
    const failedBackendResponse = await requestCallMeWithAccessToken()

    expect(await cookieResponse.json()).toStrictEqual({ data: { email: 'user@example.com', sub: 'user-1' }, ok: true })
    expect(await accessTokenResponse.json()).toStrictEqual({
      data: { email: 'user@example.com', sub: 'user-1' },
      ok: true,
    })
    expect(await missingCookieResponse.json()).toMatchObject({ ok: false })
    expect(await failedBackendResponse.json()).toMatchObject({ ok: false })
    expect(mockFetch).toHaveBeenCalledTimes(3)
    const firstRequestInput = mockFetch.mock.calls[0]?.[0]
    const firstRequestUrl = firstRequestInput instanceof URL ? firstRequestInput.href : firstRequestInput
    expect(firstRequestUrl).toBe('http://localhost:8789/api/v1/me')
    const firstRequestInit = mockFetch.mock.calls[0]?.[1]
    expect(firstRequestInit?.headers).toMatchObject({ authorization: 'Bearer stored-access-jwt' })
  })

  it('rejects backend responses that provide id without sub', async () => {
    const mockFetch = vi
      .fn<(input: RequestInfo | URL, init?: RequestInit) => Promise<Response>>()
      .mockResolvedValue(Response.json({ email: 'user@example.com', id: 'user-1' }, { status: 200 }))
    vi.stubGlobal('fetch', mockFetch)

    const response = await requestCallMeWithAccessToken()

    expect(await response.json()).toStrictEqual({ ok: false })
  })
})
