import { Hono } from 'hono'
import type { Context as HonoContext } from 'hono'
import { createFactory } from 'hono/factory'
import { describe, expect, it, vi } from 'vite-plus/test'

import { requireAuthMiddleware } from './require-auth.ts'

interface TestUser {
  readonly email: string
}

interface TestEnv {
  readonly Variables: {
    readonly user: TestUser | null
  }
}

type TestContext = HonoContext<TestEnv>

const factory = createFactory<TestEnv>()

describe('requireAuthMiddleware', () => {
  it('calls the unauthenticated handler when the request has no user', async () => {
    const onUnauthenticated = vi.fn((ctx: TestContext) => ctx.text('login required', 401))
    const middleware = requireAuthMiddleware({ factory, onUnauthenticated })
    const app = new Hono<TestEnv>()
      .use((ctx, next) => {
        ctx.set('user', null)
        return next()
      })
      .get('/protected', middleware, (ctx) => ctx.text(ctx.var.user?.email ?? 'missing'))

    const res = await app.request('/protected')

    expect(res.status).toBe(401)
    expect(await res.text()).toBe('login required')
    expect(onUnauthenticated).toHaveBeenCalledTimes(1)
  })

  it('passes authenticated requests through and returns the downstream response', async () => {
    const onUnauthenticated = vi.fn((ctx: TestContext) => ctx.text('login required', 401))
    const middleware = requireAuthMiddleware({ factory, onUnauthenticated })
    const app = new Hono<TestEnv>()
      .use((ctx, next) => {
        ctx.set('user', { email: 'test@example.com' })
        return next()
      })
      .get('/protected', middleware, (ctx) => ctx.text(ctx.var.user?.email ?? 'missing'))

    const res = await app.request('/protected')

    expect(res.status).toBe(200)
    expect(await res.text()).toBe('test@example.com')
    expect(onUnauthenticated).not.toHaveBeenCalled()
  })
})
