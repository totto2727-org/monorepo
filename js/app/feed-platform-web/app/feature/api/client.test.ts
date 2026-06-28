import { Effect, Layer, Predicate } from 'effect'
import type { HttpClientRequest } from 'effect/unstable/http'
import { HttpClient, HttpClientResponse } from 'effect/unstable/http'
import { Hono } from 'hono'
import { contextStorage } from 'hono/context-storage'
import { afterEach, describe, expect, it } from 'vite-plus/test'

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
} satisfies Env.Type

const capturedRequests: HttpClientRequest.HttpClientRequest[] = []

const makeHttpClientLayer = (response: Response) =>
  Layer.succeed(
    HttpClient.HttpClient,
    HttpClient.make((request) => {
      capturedRequests.push(request)
      return Effect.succeed(HttpClientResponse.fromWeb(request, response))
    }),
  )

const makeTestLayer = (response: Response) =>
  liveLayer.pipe(Layer.provideMerge(makeHttpClientLayer(response)), Layer.provide(Env.makeLayer(testEnv)))

const successResponse = () =>
  Promise.resolve(Response.json({ email: 'user@example.com', sub: 'user-1' }, { status: 200 }))

afterEach(() => {
  capturedRequests.length = 0
})

const requestCallMe = (response: Response, cookie?: string) => {
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
          makeTestLayer(response),
        ),
      ),
    ),
  )
  return app.request('/test', Predicate.isNullish(cookie) ? undefined : { headers: { cookie } }, testEnv)
}

describe('BackendClient', () => {
  it('fails when the backend rejects a request without a Better Auth session', async () => {
    const res = await requestCallMe(Response.json({ error: 'Unauthorized' }, { status: 401 }))
    expect(await res.json()).toStrictEqual({ ok: false })
  })

  it('forwards the Better Auth session cookie to the backend', async () => {
    const res = await requestCallMe(
      await successResponse(),
      'unrelated=value; better-auth.session_token=session-token; oauth_state=state',
    )
    expect(capturedRequests).toHaveLength(1)
    expect(capturedRequests[0]?.url).toBe('http://localhost:8789/api/v1/me')
    expect(capturedRequests[0]?.headers.cookie).toBe(
      'unrelated=value; better-auth.session_token=session-token; oauth_state=state',
    )
    expect(await res.json()).toStrictEqual({ data: { email: 'user@example.com', sub: 'user-1' }, ok: true })
  })
})
