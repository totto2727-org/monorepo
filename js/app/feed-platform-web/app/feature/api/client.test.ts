import { Effect, Layer, Predicate, Result } from 'effect'
import { FetchHttpClient } from 'effect/unstable/http'
import { Hono } from 'hono'
import { contextStorage } from 'hono/context-storage'
import { afterEach, describe, expect, it, vi } from 'vite-plus/test'

import { FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'
import * as Env from '#@/feature/env.ts'
import type { Env as HonoEnv } from '#@/feature/share/lib/hono/context.ts'

import { BackendClient, liveLayer } from './client.ts'

const testEnv = {
  BACKEND_BASE_URL: 'http://localhost:8789',
  DATABASE_AUTH_TOKEN: '',
  DATABASE_URL: ':memory:',
  IDP_BASE_URL: 'https://idp.example.com',
  OAUTH_CLIENT_ID: 'feed-platform-web',
  OAUTH_CLIENT_SECRET: 'dev-secret',
} satisfies Env.Type

const makeTestLayer = () => Layer.merge(liveLayer, FetchHttpClient.layer).pipe(Layer.provide(Env.makeLayer(testEnv)))

const successResponse = () =>
  Promise.resolve(Response.json({ email: 'user@example.com', id: 'user-1' }, { status: 200 }))

afterEach(() => {
  vi.restoreAllMocks()
  vi.unstubAllGlobals()
})

const requestCallMe = (cookie?: string) => {
  const app = new Hono<HonoEnv>().use(contextStorage()).get('/test', async (ctx) =>
    ctx.json(
      await Effect.runPromise(
        Effect.provide(
          Effect.gen(function* () {
            const client = yield* BackendClient
            const exit = yield* Effect.result(client.callMe())
            return Result.isSuccess(exit) ? { data: exit.success, ok: true } : { ok: false }
          }),
          makeTestLayer(),
        ),
      ),
    ),
  )
  return app.request('/test', Predicate.isNullish(cookie) ? undefined : { headers: { cookie } }, testEnv)
}

const requestCallMeWithAccessToken = () => {
  const app = new Hono<HonoEnv>().use(contextStorage()).get('/test', async (ctx) =>
    ctx.json(
      await Effect.runPromise(
        Effect.provide(
          Effect.gen(function* () {
            const client = yield* BackendClient
            const exit = yield* Effect.result(client.callMeWithAccessToken('test-jwt'))
            return Result.isSuccess(exit) ? { data: exit.success, ok: true } : { ok: false }
          }),
          makeTestLayer(),
        ),
      ),
    ),
  )
  return app.request('/test', undefined, testEnv)
}

describe('BackendClient.callMe', () => {
  it('reads authorization from Hono context and supports refresh-token retry calls', async () => {
    const mockFetch = vi
      .fn()
      .mockImplementationOnce(successResponse)
      .mockImplementationOnce(successResponse)
      .mockImplementationOnce(() => Promise.resolve(new Response(null, { status: 401 })))
    vi.stubGlobal('fetch', mockFetch)

    const cookieResponse = await requestCallMe(`${FEED_SESSION_COOKIE}=test-jwt`)
    const accessTokenResponse = await requestCallMeWithAccessToken()
    const missingCookieResponse = await requestCallMe()
    const failedBackendResponse = await requestCallMeWithAccessToken()

    expect(await cookieResponse.json()).toStrictEqual({ data: { email: 'user@example.com', id: 'user-1' }, ok: true })
    expect(await accessTokenResponse.json()).toStrictEqual({
      data: { email: 'user@example.com', id: 'user-1' },
      ok: true,
    })
    expect(await missingCookieResponse.json()).toMatchObject({ ok: false })
    expect(await failedBackendResponse.json()).toMatchObject({ ok: false })
    expect(mockFetch).toHaveBeenCalledTimes(3)
  })
})
