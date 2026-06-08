import { Hono } from 'hono'
import { beforeEach, describe, expect, it, vi } from 'vite-plus/test'

import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'

const { mockGetSession } = vi.hoisted(() => ({ mockGetSession: vi.fn() }))

vi.mock('better-auth', () => ({
  betterAuth: vi.fn(() => ({
    api: { getSession: mockGetSession },
  })),
}))

vi.mock('better-auth/plugins', () => ({
  bearer: vi.fn(() => ({})),
  genericOAuth: vi.fn(() => ({})),
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
  it('sets user to null when Better Auth has no session', async () => {
    mockGetSession.mockResolvedValue(null)
    const app = makeApp()
    const res = await app.request('/test')
    expect(res.status).toBe(200)
    expect(await res.json()).toStrictEqual({ user: null })
  })

  it('sets user from a Better Auth stateless session', async () => {
    mockGetSession.mockResolvedValue({
      user: { email: 'test@example.com', id: 'user-123' },
    })
    const app = makeApp()
    const res = await app.request('/test', { headers: { cookie: 'better-auth.session_token=session-token' } })
    expect(res.status).toBe(200)
    expect(await res.json()).toStrictEqual({ user: { email: 'test@example.com', sub: 'user-123' } })
  })

  it('sets user to null when Better Auth user shape is invalid', async () => {
    mockGetSession.mockResolvedValue({ user: { id: 'user-123' } })
    const app = makeApp()
    const res = await app.request('/test', { headers: { cookie: 'better-auth.session_token=session-token' } })
    expect(res.status).toBe(200)
    expect(await res.json()).toStrictEqual({ user: null })
  })
})
