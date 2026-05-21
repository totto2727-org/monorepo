import { Effect, Exit } from 'effect'
import { beforeEach, describe, expect, it, vi } from 'vite-plus/test'

const mockJwtVerify = vi.fn()
const mockCreateRemoteJWKSet = vi.fn().mockReturnValue({})

vi.mock('jose', () => ({
  createRemoteJWKSet: mockCreateRemoteJWKSet,
  jwtVerify: mockJwtVerify,
}))

const { JwtService, liveLayer } = await import('./jwt.ts')

const runVerify = (token: string) =>
  Effect.runPromiseExit(
    Effect.provide(
      Effect.gen(function* () {
        const jwt = yield* JwtService
        return yield* jwt.verify(token)
      }),
      liveLayer,
    ),
  )

beforeEach(() => {
  vi.clearAllMocks()
})

describe('JwtService', () => {
  it('returns payload for a valid JWT', async () => {
    mockJwtVerify.mockResolvedValue({
      payload: { exp: 9_999_999, iat: 1_000_000, sub: 'user-123' },
    })
    const exit = await runVerify('valid.jwt.token')
    expect(Exit.isSuccess(exit)).toBe(true)
    if (Exit.isSuccess(exit)) {
      expect(exit.value).toStrictEqual({ exp: 9_999_999, iat: 1_000_000, sub: 'user-123' })
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

  it('createRemoteJWKSet is called once at module scope (JWKS cache)', async () => {
    mockJwtVerify.mockResolvedValue({
      payload: { exp: 9_999_999, iat: 1_000_000, sub: 'user-1' },
    })
    await runVerify('token-1')
    await runVerify('token-2')
    expect(mockCreateRemoteJWKSet).toHaveBeenCalledTimes(0)
  })
})
