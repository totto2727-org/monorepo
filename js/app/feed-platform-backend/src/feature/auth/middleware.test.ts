import { Hono } from 'hono'
import { beforeEach, describe, expect, it, vi } from 'vite-plus/test'

import type * as AppEnv from '#@/feature/env.ts'
import type { Env } from '#@/feature/share/lib/hono/context.ts'

const { mockGetSession } = vi.hoisted(() => ({ mockGetSession: vi.fn() }))

vi.mock('better-auth', () => ({
  betterAuth: vi.fn(() => ({
    api: { getSession: mockGetSession },
  })),
}))

vi.mock('better-auth/plugins', () => ({
  bearer: vi.fn(() => ({})),
}))

const { authMiddleware } = await import('./middleware.ts')
const { middleware: runtimeMiddleware } = await import('#@/feature/runtime/hono.ts')

const localBindings = {
  BETTER_AUTH_SECRET: '0123456789abcdef0123456789abcdef0123456789abcdef',
  WEB_BASE_URL: 'http://127.0.0.1:8789',
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
  it('sets user and passes through for a valid Better Auth session', async () => {
    mockGetSession.mockResolvedValue({ user: { email: 'user@example.com', id: 'user-123' } })
    const app = makeApp()
    const res = await app.request(
      '/api/v1/me',
      { headers: { Cookie: 'better-auth.session_token=session-token' } },
      localBindings,
    )
    expect(res.status).toBe(200)
    expect(await res.json()).toStrictEqual({ email: 'user@example.com', sub: 'user-123' })
  })

  it('returns 401 when Better Auth has no session', async () => {
    mockGetSession.mockResolvedValue(null)
    const app = makeApp()
    const res = await app.request('/api/v1/me', {}, localBindings)
    expect(res.status).toBe(401)
    expect(res.headers.get('WWW-Authenticate')).toBe('Session error="invalid_session"')
  })

  it('returns 401 for an invalid Better Auth user shape', async () => {
    mockGetSession.mockResolvedValue({ user: { id: 'user-123' } })
    const app = makeApp()
    const res = await app.request(
      '/api/v1/me',
      { headers: { Cookie: 'better-auth.session_token=session-token' } },
      localBindings,
    )
    expect(res.status).toBe(401)
  })
})
