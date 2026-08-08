import { describe, expect, it, vi } from 'vite-plus/test'

import type * as AuthMiddlewareModule from '#@/feature/auth/middleware.ts'

import app from './app.tsx'
import { loginReturnToCookieName } from './feature/auth/cookie.ts'
import {
  preserveReturnToQueryParameterName,
  preserveReturnToQueryParameterValue,
} from './feature/auth/query-parameter.ts'

vi.mock('#@/feature/runtime/hono.ts', async () => {
  const { factory } = await import('#@/feature/share/lib/hono/factory.ts')
  return {
    middleware: factory.createMiddleware(async (_ctx, next) => {
      await next()
    }),
  }
})

vi.mock('#@/feature/auth/middleware.ts', async (importOriginal) => {
  const actual = await importOriginal<typeof AuthMiddlewareModule>()
  const { factory } = await import('#@/feature/share/lib/hono/factory.ts')
  return {
    ...actual,
    authMiddleware: factory.createMiddleware(async (ctx, next) => {
      if (ctx.req.header('x-test-authenticated') === 'true') {
        ctx.set('user', {
          email: 'test@example.com',
          id: 'user-123',
        })
      }
      await next()
    }),
  }
})

const authenticatedHeaders = {
  'x-test-authenticated': 'true',
} as const

describe('login return-to session routes', () => {
  it('open_login_preserve renders login without overwriting the stored target', async () => {
    const res = await app.request(
      `/login?${preserveReturnToQueryParameterName}=${preserveReturnToQueryParameterValue}`,
      {
        headers: {
          cookie: `${loginReturnToCookieName}=%2Fapp%2Foriginal`,
        },
      },
    )

    expect(res.status).toBe(200)
    expect(res.headers.get('set-cookie')).toBeNull()
  })

  it('open_login_oauth stores the local OAuth authorize target and renders login', async () => {
    const res = await app.request(
      '/login?client_id=client-123&redirect_uri=https%3A%2F%2Fclient.example%2Fcallback&scope=openid',
    )

    expect(res.status).toBe(200)
    expect(res.headers.get('set-cookie')).toEqual(
      expect.stringContaining(
        `${loginReturnToCookieName}=%2Fapi%2Fv1%2Fauth%2Foauth2%2Fauthorize%3Fclient_id%3Dclient-123%26redirect_uri%3Dhttps%253A%252F%252Fclient.example%252Fcallback%26scope%3Dopenid`,
      ),
    )
  })

  it('open_login_unrelated clears a stale stored target and renders login', async () => {
    const res = await app.request('/login', {
      headers: {
        cookie: `${loginReturnToCookieName}=%2Fapp%2Foriginal`,
      },
    })

    expect(res.status).toBe(200)
    expect(res.headers.get('set-cookie')).toEqual(expect.stringContaining(`${loginReturnToCookieName}=;`))
    expect(res.headers.get('set-cookie')).toEqual(expect.stringContaining('Max-Age=0'))
  })

  it('callback_without_session redirects to login without consuming the stored target', async () => {
    const res = await app.request('/login/callback', {
      headers: {
        cookie: `${loginReturnToCookieName}=%2Fapp%2Faccount%3Ftab%3Dsecurity`,
      },
    })

    expect(res.status).toBe(302)
    expect(res.headers.get('location')).toBe('/login')
    expect(res.headers.get('set-cookie')).toBeNull()
  })

  it('callback_with_session redirects to the stored local target and consumes it', async () => {
    const res = await app.request('/login/callback', {
      headers: {
        ...authenticatedHeaders,
        cookie: `${loginReturnToCookieName}=%2Fapp%2Faccount%3Ftab%3Dsecurity`,
      },
    })

    expect(res.status).toBe(302)
    expect(res.headers.get('location')).toBe('/app/account?tab=security')
    expect(res.headers.get('set-cookie')).toContain(`${loginReturnToCookieName}=;`)
    expect(res.headers.get('set-cookie')).toContain('Max-Age=0')
  })

  it('callback_after_consumption redirects an authenticated replay to the account fallback', async () => {
    const res = await app.request('/login/callback', {
      headers: authenticatedHeaders,
    })

    expect(res.status).toBe(302)
    expect(res.headers.get('location')).toBe('/app/account')
  })

  it('callback_with_session never redirects to an external origin from a stored target', async () => {
    const res = await app.request('/login/callback', {
      headers: {
        ...authenticatedHeaders,
        cookie: `${loginReturnToCookieName}=https%3A%2F%2Fevil.example%2Fsteal%3Ftoken%3Dsecret`,
      },
    })

    expect(res.status).toBe(302)
    expect(res.headers.get('location')).toBe('/steal?token=secret')
  })
})
