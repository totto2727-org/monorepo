import { FEED_SESSION_COOKIE } from 'auth-helper'
import { Hono } from 'hono'
import { beforeEach, describe, expect, it, vi } from 'vite-plus/test'

const mockJwtVerify = vi.fn()

vi.mock('jose', () => ({
  createRemoteJWKSet: vi.fn().mockReturnValue({}),
  jwtVerify: mockJwtVerify,
}))

const { authMiddleware } = await import('./middleware.ts')

const makeApp = () =>
  new Hono<{ Variables: { user: { id: string; email: string } | null } }>()
    .use('*', authMiddleware)
    .get('/test', (c) => c.json({ user: c.var.user }))

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
    const res = await app.request('/test', {
      headers: { cookie: `${FEED_SESSION_COOKIE}=valid.jwt.token` },
    })
    expect(res.status).toBe(200)
    expect(await res.json()).toStrictEqual({ user: { email: 'test@example.com', id: 'user-123' } })
  })

  it('sets user to null when JWT verification fails', async () => {
    mockJwtVerify.mockRejectedValue(new Error('Invalid JWT'))
    const app = makeApp()
    const res = await app.request('/test', {
      headers: { cookie: `${FEED_SESSION_COOKIE}=tampered.jwt.token` },
    })
    expect(res.status).toBe(200)
    expect(await res.json()).toStrictEqual({ user: null })
  })
})
