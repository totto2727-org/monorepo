import { Hono } from 'hono'
import { contextStorage } from 'hono/context-storage'
import { beforeEach, describe, expect, it, vi } from 'vite-plus/test'

import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'

const { mockBetterAuth, mockGetSession } = vi.hoisted(() => {
  const getSession = vi.fn()
  return {
    mockBetterAuth: vi.fn(() => ({
      api: { getSession },
    })),
    mockGetSession: getSession,
  }
})

vi.mock('better-auth', () => ({
  betterAuth: mockBetterAuth,
}))

vi.mock('better-auth/plugins', () => ({
  bearer: vi.fn(() => ({})),
  genericOAuth: vi.fn(() => ({})),
}))

const { loginReturnToCookieName } = await import('./cookie.ts')
const { authMiddleware, requireAuthMiddleware } = await import('./middleware.ts')
const { preserveReturnToQueryParameterName, preserveReturnToQueryParameterValue } = await import('./query-parameter.ts')

const makeApp = () =>
  new Hono<{ Variables: { user: { email: string; id: string } | null } }>()
    .use('*', contextStorage())
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
    expect(await res.json()).toStrictEqual({ user: { email: 'test@example.com', id: 'user-123' } })
    expect(mockBetterAuth).toHaveBeenCalledTimes(1)
  })

  it('sets user to null when Better Auth user shape is invalid', async () => {
    mockGetSession.mockResolvedValue({ user: { id: 'user-123' } })
    const app = makeApp()
    const res = await app.request('/test', { headers: { cookie: 'better-auth.session_token=session-token' } })
    expect(res.status).toBe(200)
    expect(await res.json()).toStrictEqual({ user: null })
  })
})

describe('requireAuthMiddleware', () => {
  const makeProtectedApp = () =>
    new Hono<{ Variables: { user: { email: string; id: string } | null } }>()
      .use('*', contextStorage())
      .use('*', runtimeMiddleware)
      .use('*', authMiddleware)
      .get('/app/settings', requireAuthMiddleware, (ctx) => ctx.text(ctx.var.user?.email ?? 'missing'))

  it('redirects unauthenticated app requests to login with a return-to cookie', async () => {
    mockGetSession.mockResolvedValue(null)
    const app = makeProtectedApp()
    const res = await app.request('/app/settings?tab=profile')
    expect(res.status).toBe(302)
    expect(res.headers.get('location')).toBe(
      `/app/login?${preserveReturnToQueryParameterName}=${preserveReturnToQueryParameterValue}`,
    )
    expect(res.headers.get('set-cookie')).toContain(`${loginReturnToCookieName}=%2Fapp%2Fsettings%3Ftab%3Dprofile`)
  })

  it('passes authenticated app requests through', async () => {
    mockGetSession.mockResolvedValue({ user: { email: 'test@example.com', id: 'user-123' } })
    const app = makeProtectedApp()
    const res = await app.request('/app/settings', { headers: { cookie: 'better-auth.session_token=session-token' } })
    expect(res.status).toBe(200)
    expect(await res.text()).toBe('test@example.com')
  })
})
