import { Hono } from 'hono'
import { beforeEach, describe, expect, it, vi } from 'vite-plus/test'

import type { AppJWTPayload } from '#@/feature/auth/jwt-payload.ts'

const mockJwtVerify = vi.fn()

vi.mock('jose', () => ({
  createRemoteJWKSet: vi.fn().mockReturnValue({}),
  jwtVerify: mockJwtVerify,
}))

const { authMiddleware } = await import('./middleware.ts')

const makeApp = () =>
  new Hono<{ Variables: { user: AppJWTPayload } }>()
    .use('/api/*', authMiddleware)
    .get('/api/v1/me', (c) => c.json(c.var.user))

beforeEach(() => {
  vi.clearAllMocks()
})

describe('authMiddleware', () => {
  it('sets user and passes through for a valid Bearer token', async () => {
    mockJwtVerify.mockResolvedValue({
      payload: {
        email: 'user@example.com',
        exp: 9_999_999,
        iat: 1_000_000,
        sub: 'user-123',
      },
    })
    const app = makeApp()
    const res = await app.request('/api/v1/me', {
      headers: { Authorization: 'Bearer valid.jwt.token' },
    })
    expect(res.status).toBe(200)
    expect(await res.json()).toStrictEqual({
      email: 'user@example.com',
      exp: 9_999_999,
      iat: 1_000_000,
      sub: 'user-123',
    })
  })

  it('returns 401 when Authorization header is absent', async () => {
    const app = makeApp()
    const res = await app.request('/api/v1/me')
    expect(res.status).toBe(401)
    expect(res.headers.get('WWW-Authenticate')).toBe('Bearer error="invalid_token"')
  })

  it('returns 401 when only a Cookie is present (no Authorization)', async () => {
    const app = makeApp()
    const res = await app.request('/api/v1/me', {
      headers: { Cookie: 'feed-session=valid.jwt.token' },
    })
    expect(res.status).toBe(401)
  })

  it('returns 401 for an invalid Bearer token', async () => {
    mockJwtVerify.mockRejectedValue(new Error('signature verification failed'))
    const app = makeApp()
    const res = await app.request('/api/v1/me', {
      headers: { Authorization: 'Bearer tampered.jwt.token' },
    })
    expect(res.status).toBe(401)
    expect(res.headers.get('WWW-Authenticate')).toBe('Bearer error="invalid_token"')
  })
})
