import { Effect, Layer, Predicate } from 'effect'
import { FetchHttpClient } from 'effect/unstable/http'
import { Hono } from 'hono'
import { contextStorage } from 'hono/context-storage'
import { afterEach, describe, expect, it, vi } from 'vite-plus/test'

import * as Env from '#@/feature/env.ts'
import type { Env as HonoEnv } from '#@/feature/share/lib/hono/context.ts'

import { BackendClient, liveLayer } from './client.ts'

const testEnv = {
  BACKEND_BASE_URL: 'http://localhost:8789',
  BETTER_AUTH_SECRET: '0123456789abcdef0123456789abcdef0123456789abcdef',
  DATABASE_AUTH_TOKEN: '',
  DATABASE_URL: ':memory:',
  IDP_BASE_URL: 'https://idp.example.com',
  OAUTH_CLIENT_ID: 'feed-platform-web',
  OAUTH_CLIENT_SECRET: 'dev-secret',
  WEB_BASE_URL: 'http://127.0.0.1:8789',
} satisfies Env.Type

const makeTestLayer = () =>
  liveLayer.pipe(Layer.provideMerge(FetchHttpClient.layer), Layer.provide(Env.makeLayer(testEnv)))

const successResponse = () =>
  Promise.resolve(Response.json({ email: 'user@example.com', sub: 'user-1' }, { status: 200 }))

const getRequestUrl = (input: RequestInfo | URL): string => {
  if (Predicate.isString(input)) {
    return input
  }
  if (input instanceof URL) {
    return input.href
  }
  return input.url
}

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
            return yield* client.callMe().pipe(
              Effect.match({
                onFailure: () => ({ ok: false }),
                onSuccess: (data) => ({ data, ok: true }),
              }),
            )
          }),
          makeTestLayer(),
        ),
      ),
    ),
  )
  return app.request('/test', Predicate.isNullish(cookie) ? undefined : { headers: { cookie } }, testEnv)
}

describe('BackendClient', () => {
  it('fails when the Better Auth session cookie is absent', async () => {
    const res = await requestCallMe()
    expect(await res.json()).toStrictEqual({ ok: false })
  })

  it('forwards the Better Auth session cookie to the backend', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockImplementation((input, init) => {
      expect(getRequestUrl(input)).toBe('http://localhost:8789/api/v1/me')
      expect(new Headers(init?.headers).get('Cookie')).toBe('better-auth.session_token=session-token')
      return successResponse()
    })

    const res = await requestCallMe('unrelated=value; better-auth.session_token=session-token; oauth_state=state')
    expect(await res.json()).toStrictEqual({ data: { email: 'user@example.com', sub: 'user-1' }, ok: true })
    expect(fetchSpy).toHaveBeenCalledTimes(1)
  })
})
