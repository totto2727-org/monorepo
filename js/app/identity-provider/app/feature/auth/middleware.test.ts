import { DateTime, Predicate } from 'effect'
import { Hono } from 'hono'
import { contextStorage } from 'hono/context-storage'
import { describe, expect, it } from 'vite-plus/test'

import type { Env } from '#@/feature/share/lib/hono/context.ts'

import { loginReturnToCookieName } from './cookie.ts'
import { requireAuthMiddleware } from './middleware.ts'
import { preserveReturnToLoginPath } from './query-parameter.ts'

const makeProtectedApp = (user: Env['Variables']['user'] | null) =>
  new Hono<Env>()
    .use(contextStorage())
    .use((ctx, next) => {
      if (Predicate.isNotNull(user)) {
        ctx.set('user', user)
      }
      return next()
    })
    .get('/app/account', requireAuthMiddleware, (ctx) => ctx.text(ctx.var.user?.email ?? 'missing'))

describe('requireAuthMiddleware', () => {
  it('redirects unauthenticated app requests to login with a return-to cookie', async () => {
    const app = makeProtectedApp(null)

    const res = await app.request('/app/account?tab=security')

    expect(res.status).toBe(302)
    expect(res.headers.get('location')).toBe(preserveReturnToLoginPath)
    expect(res.headers.get('set-cookie')).toContain(`${loginReturnToCookieName}=%2Fapp%2Faccount%3Ftab%3Dsecurity`)
  })

  it('passes authenticated app requests through', async () => {
    const app = makeProtectedApp({
      createdAt: DateTime.makeUnsafe('2026-07-05T00:00:00.000Z'),
      email: 'test@example.com',
      id: 'user-123',
    })

    const res = await app.request('/app/account')

    expect(res.status).toBe(200)
    expect(await res.text()).toBe('test@example.com')
  })
})
