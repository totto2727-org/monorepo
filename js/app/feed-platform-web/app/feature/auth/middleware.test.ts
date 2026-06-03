import { Hono } from 'hono'
import { beforeEach, describe, expect, it, vi } from 'vite-plus/test'

import { FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'

const mockJwtVerify = vi.fn()

vi.mock('jose', () => ({
  createRemoteJWKSet: vi.fn().mockReturnValue({}),
  jwtVerify: mockJwtVerify,
}))

const { authMiddleware } = await import('./middleware.ts')

const makeApp = () =>
  new Hono<{ Variables: { user: { email: string; sub: string } | null } }>()
    .use('*', runtimeMiddleware)
    .use('*', authMiddleware)
    .get('/test', (ctx) => ctx.json({ user: ctx.var.user }))

beforeEach(() => {
  vi.clearAllMocks()
})

describe('authMiddleware', () => {
  it('sets user to null when no cookie present', async () => {
    const app = makeApp()
    const res = await app.request('/test')
    expect(res.status).toBe(200)
    expect(await res.json()).toStrictEqual({ user: null })
  })

  it('sets user from valid JWT payload', async () => {
    mockJwtVerify.mockResolvedValue({
      payload: { email: 'test@example.com', sub: 'user-123' },
    })
    const app = makeApp()
    const res = await app.request('/test', { headers: { cookie: `${FEED_SESSION_COOKIE}=valid.jwt.token` } })
    expect(res.status).toBe(200)
    expect(await res.json()).toStrictEqual({ user: { email: 'test@example.com', sub: 'user-123' } })
  })

  it('sets user to null when JWT payload shape is invalid', async () => {
    mockJwtVerify.mockResolvedValue({
      payload: { sub: 'user-123' },
    })
    const app = makeApp()
    const res = await app.request('/test', { headers: { cookie: `${FEED_SESSION_COOKIE}=invalid-payload.jwt.token` } })
    expect(res.status).toBe(200)
    expect(await res.json()).toStrictEqual({ user: null })
  })

  it('sets user to null when JWT verification fails', async () => {
    mockJwtVerify.mockRejectedValue(new Error('Invalid JWT'))
    const app = makeApp()
    const res = await app.request('/test', { headers: { cookie: `${FEED_SESSION_COOKIE}=tampered.jwt.token` } })
    expect(res.status).toBe(200)
    expect(await res.json()).toStrictEqual({ user: null })
  })
})
