import { Hono } from 'hono'
import { beforeEach, describe, expect, it, vi } from 'vite-plus/test'

import type * as AppEnv from '#@/feature/env.ts'
import type { Env } from '#@/feature/share/lib/hono/context.ts'

const { mockJwtVerify } = vi.hoisted(() => ({ mockJwtVerify: vi.fn() }))

vi.mock('jose', () => ({
  createRemoteJWKSet: vi.fn().mockReturnValue({}),
  jwtVerify: mockJwtVerify,
}))

const { authMiddleware } = await import('./middleware.ts')
const { middleware: runtimeMiddleware } = await import('#@/feature/runtime/hono.ts')
const { default: bffWorker } = await import('#@/worker/bff/worker.ts')

const localBindings = {
  FEED_PLATFORM_AUDIENCE: 'feed-platform-web',
  IDP_BASE_URL: 'http://localhost:8787',
  IDP_JWKS_URL: 'http://localhost:8787/api/v1/auth/jwks',
} satisfies AppEnv.Type

const makeApp = () => {
  const app = new Hono<Env>()
  app.use(runtimeMiddleware)
  app.use('/api/*', authMiddleware)
  app.get('/api/v1/me', (ctx) => ctx.json(ctx.var.user))
  return app
}

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
    const res = await app.request('/api/v1/me', { headers: { Authorization: 'Bearer valid.jwt.token' } }, localBindings)
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
    const res = await app.request('/api/v1/me', {}, localBindings)
    expect(res.status).toBe(401)
    expect(res.headers.get('WWW-Authenticate')).toBe('Bearer error="invalid_token"')
  })

  it('returns 401 when only a Cookie is present (no Authorization)', async () => {
    const app = makeApp()
    const res = await app.request('/api/v1/me', { headers: { Cookie: 'feed-session=valid.jwt.token' } }, localBindings)
    expect(res.status).toBe(401)
  })

  it('returns 401 for an invalid Bearer token', async () => {
    mockJwtVerify.mockRejectedValue(new Error('signature verification failed'))
    const app = makeApp()
    const res = await app.request(
      '/api/v1/me',
      { headers: { Authorization: 'Bearer tampered.jwt.token' } },
      localBindings,
    )
    expect(res.status).toBe(401)
    expect(res.headers.get('WWW-Authenticate')).toBe('Bearer error="invalid_token"')
  })

  it('protects /api/v1/me through the exported BFF worker', async () => {
    mockJwtVerify.mockResolvedValue({
      payload: {
        email: 'worker@example.com',
        exp: 9_999_999,
        iat: 1_000_000,
        sub: 'worker-user',
      },
    })
    const res = await bffWorker.request(
      '/api/v1/me',
      { headers: { Authorization: 'Bearer worker.jwt.token' } },
      localBindings,
    )
    expect(res.status).toBe(200)
    expect(await res.json()).toStrictEqual({
      email: 'worker@example.com',
      exp: 9_999_999,
      iat: 1_000_000,
      sub: 'worker-user',
    })
  })
})
