import { Effect, Exit, Layer } from 'effect'
import type { HttpClient } from 'effect/unstable/http'
import { FetchHttpClient } from 'effect/unstable/http'
import { afterEach, describe, expect, it, vi } from 'vite-plus/test'

import * as Env from '#@/feature/env.ts'

import { BackendClient, liveLayer } from './client.ts'

const testEnv = {
  BACKEND_BASE_URL: 'http://localhost:8789',
  DATABASE_AUTH_TOKEN: '',
  DATABASE_URL: ':memory:',
  IDP_BASE_URL: 'https://idp.example.com',
  OAUTH_CLIENT_ID: 'feed-platform-web',
  OAUTH_CLIENT_SECRET: 'dev-secret',
} satisfies Env.Type

const testLayer = Layer.merge(liveLayer, FetchHttpClient.layer).pipe(Layer.provide(Env.makeLayer(testEnv)))

afterEach(() => {
  vi.restoreAllMocks()
})

const runWith = <A, E>(effect: Effect.Effect<A, E, typeof BackendClient.Identifier | HttpClient.HttpClient>) =>
  Effect.runPromise(Effect.provide(effect, testLayer))

describe('BackendClient.callMe', () => {
  it('returns the decoded user from the backend', async () => {
    const mockFetch = vi
      .fn()
      .mockResolvedValue(Response.json({ email: 'user@example.com', id: 'user-1' }, { status: 200 }))
    vi.stubGlobal('fetch', mockFetch)

    const result = await runWith(
      Effect.gen(function* () {
        const client = yield* BackendClient
        return yield* client.callMe('Bearer test-jwt')
      }),
    )

    expect(result).toStrictEqual({ email: 'user@example.com', id: 'user-1' })
    expect(mockFetch).toHaveBeenCalledTimes(1)
  })

  it('fails with BackendError when authorization is null', async () => {
    const exit = await Effect.runPromiseExit(
      Effect.provide(
        Effect.gen(function* () {
          const client = yield* BackendClient
          return yield* client.callMe(null)
        }),
        testLayer,
      ),
    )

    expect(Exit.isFailure(exit)).toBe(true)
  })

  it('fails with BackendError when response is not ok', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response(null, { status: 401 })))

    const exit = await Effect.runPromiseExit(
      Effect.provide(
        Effect.gen(function* () {
          const client = yield* BackendClient
          return yield* client.callMe('Bearer bad-jwt')
        }),
        testLayer,
      ),
    )

    expect(Exit.isFailure(exit)).toBe(true)
  })
})
