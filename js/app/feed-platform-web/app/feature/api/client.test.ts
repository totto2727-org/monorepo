import { Effect, Exit } from 'effect'
import { afterEach, describe, expect, it, vi } from 'vite-plus/test'

import { BackendClient, liveLayer } from './client.ts'

afterEach(() => {
  vi.restoreAllMocks()
})

const runWith = <A, E>(effect: Effect.Effect<A, E, typeof BackendClient.Identifier>) =>
  Effect.runPromise(Effect.provide(effect, liveLayer))

describe('BackendClient.callMe', () => {
  it('sends the supplied Authorization Bearer header to backend', async () => {
    const mockFetch = vi.fn().mockResolvedValue({
      json: () => Promise.resolve({ email: 'user@example.com', id: 'user-1' }),
      ok: true,
    })
    vi.stubGlobal('fetch', mockFetch)

    const result = await runWith(
      Effect.gen(function* () {
        const client = yield* BackendClient
        return yield* client.callMe('Bearer test-jwt')
      }),
    )

    expect(result).toStrictEqual({ email: 'user@example.com', id: 'user-1' })
    expect(mockFetch).toHaveBeenCalledWith(
      expect.stringContaining('/api/v1/me'),
      expect.objectContaining({ headers: { Authorization: 'Bearer test-jwt' } }),
    )
  })

  it('fails with BackendError when authorization is null', async () => {
    const exit = await Effect.runPromiseExit(
      Effect.provide(
        Effect.gen(function* () {
          const client = yield* BackendClient
          return yield* client.callMe(null)
        }),
        liveLayer,
      ),
    )

    expect(Exit.isFailure(exit)).toBe(true)
  })

  it('fails with BackendError when response is not ok', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 401 }))

    const exit = await Effect.runPromiseExit(
      Effect.provide(
        Effect.gen(function* () {
          const client = yield* BackendClient
          return yield* client.callMe('Bearer bad-jwt')
        }),
        liveLayer,
      ),
    )

    expect(Exit.isFailure(exit)).toBe(true)
  })
})
