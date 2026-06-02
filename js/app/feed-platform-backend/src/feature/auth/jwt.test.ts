import { Effect, Exit, Layer } from 'effect'
import { beforeEach, describe, expect, it, vi } from 'vite-plus/test'

import * as AppEnv from '../env.ts'

const mockJwtVerify = vi.fn()
const mockCreateRemoteJWKSet = vi.fn().mockReturnValue({})

vi.mock('jose', () => ({
  createRemoteJWKSet: mockCreateRemoteJWKSet,
  jwtVerify: mockJwtVerify,
}))

const { Service, layer } = await import('./jwt.ts')

const localBindings = {
  FEED_PLATFORM_AUDIENCE: 'feed-platform-web',
  IDP_BASE_URL: 'http://localhost:8787',
  IDP_JWKS_URL: 'http://localhost:8787/api/v1/auth/jwks',
} satisfies AppEnv.Type

const runVerify = (token: string) =>
  Effect.runPromiseExit(
    Effect.provide(
      Effect.gen(function* () {
        const jwt = yield* Service
        return yield* jwt.verify(token)
      }),
      layer.pipe(Layer.provide(AppEnv.makeLayer(localBindings))),
    ),
  )

beforeEach(() => {
  vi.clearAllMocks()
})

describe('JwtService', () => {
  it('returns payload for a valid JWT', async () => {
    mockJwtVerify.mockResolvedValue({
      payload: {
        email: 'user@example.com',
        exp: 9_999_999,
        iat: 1_000_000,
        sub: 'user-123',
      },
    })
    const exit = await runVerify('valid.jwt.token')
    expect(Exit.isSuccess(exit)).toBe(true)
    if (Exit.isSuccess(exit)) {
      expect(exit.value).toStrictEqual({
        email: 'user@example.com',
        exp: 9_999_999,
        iat: 1_000_000,
        sub: 'user-123',
      })
    }
  })

  it('returns payload without iat/exp when IdP omits them', async () => {
    mockJwtVerify.mockResolvedValue({
      payload: { email: 'user@example.com', sub: 'user-123' },
    })
    const exit = await runVerify('short.lived.token')
    expect(Exit.isSuccess(exit)).toBe(true)
    if (Exit.isSuccess(exit)) {
      expect(exit.value).toStrictEqual({
        email: 'user@example.com',
        sub: 'user-123',
      })
    }
  })

  it('fails with JwtVerifyError for an invalid JWT', async () => {
    mockJwtVerify.mockRejectedValue(new Error('signature verification failed'))
    const exit = await runVerify('tampered.jwt.token')
    expect(Exit.isFailure(exit)).toBe(true)
  })

  it('fails with JwtVerifyError for wrong issuer', async () => {
    mockJwtVerify.mockRejectedValue(new Error('unexpected "iss" claim value'))
    const exit = await runVerify('wrong-issuer.jwt.token')
    expect(Exit.isFailure(exit)).toBe(true)
  })

  it('fails with JwtVerifyError when email claim is missing', async () => {
    mockJwtVerify.mockResolvedValue({
      payload: { exp: 9_999_999, iat: 1_000_000, sub: 'user-123' },
    })
    const exit = await runVerify('no-email.jwt.token')
    expect(Exit.isFailure(exit)).toBe(true)
  })

  it('createRemoteJWKSet is called lazily inside the layer (JWKS cache by URL)', async () => {
    const testLayer = layer.pipe(
      Layer.provide(
        AppEnv.makeLayer({
          FEED_PLATFORM_AUDIENCE: 'feed-platform-web',
          IDP_BASE_URL: 'http://localhost:8787',
          IDP_JWKS_URL: 'http://localhost:8787/api/v1/auth/jwks-cache-test',
        }),
      ),
    )
    const runVerifyWithTestEnv = (token: string) =>
      Effect.runPromiseExit(
        Effect.provide(
          Effect.gen(function* () {
            const jwt = yield* Service
            return yield* jwt.verify(token)
          }),
          testLayer,
        ),
      )

    mockJwtVerify.mockResolvedValue({
      payload: {
        email: 'user@example.com',
        exp: 9_999_999,
        iat: 1_000_000,
        sub: 'user-1',
      },
    })
    expect(mockCreateRemoteJWKSet).toHaveBeenCalledTimes(0)
    await runVerifyWithTestEnv('token-1')
    await runVerifyWithTestEnv('token-2')
    expect(mockCreateRemoteJWKSet).toHaveBeenCalledTimes(1)
  })
})
