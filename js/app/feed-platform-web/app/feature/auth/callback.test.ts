import { Hono } from 'hono'
import { afterEach, describe, expect, it, vi } from 'vite-plus/test'

import { FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'

import { handleAuthCallback } from './callback.ts'

const makeApp = () => new Hono().get('/auth/callback', (c) => handleAuthCallback(c))

const makeCookieHeader = (pairs: Record<string, string>) =>
  Object.entries(pairs)
    .map(([k, v]) => `${k}=${v}`)
    .join('; ')

afterEach(() => {
  vi.restoreAllMocks()
})

describe('handleAuthCallback', () => {
  it('returns 403 when state mismatches', async () => {
    const app = makeApp()
    const res = await app.request('/auth/callback?code=abc&state=wrong', {
      headers: { cookie: makeCookieHeader({ oauth_state: 'correct', pkce_verifier: 'ver' }) },
    })
    expect(res.status).toBe(403)
  })

  it('redirects to /dashboard and sets feed-session on success', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        json: () => Promise.resolve({ access_token: 'jwt-token-here' }),
        ok: true,
      }),
    )
    const app = makeApp()
    const res = await app.request('/auth/callback?code=authcode&state=mystate', {
      headers: { cookie: makeCookieHeader({ oauth_state: 'mystate', pkce_verifier: 'verifier123' }) },
    })
    expect(res.status).toBe(302)
    expect(res.headers.get('location')).toBe('/dashboard')
    const cookies = res.headers.getSetCookie()
    expect(cookies.some((c) => c.startsWith(`${FEED_SESSION_COOKIE}=jwt-token-here`))).toBe(true)
  })

  it('returns 401 when token endpoint returns non-200', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false }))
    const app = makeApp()
    const res = await app.request('/auth/callback?code=authcode&state=mystate', {
      headers: { cookie: makeCookieHeader({ oauth_state: 'mystate', pkce_verifier: 'verifier123' }) },
    })
    expect(res.status).toBe(401)
  })

  it('returns 401 when access_token is missing from response', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        json: () => Promise.resolve({ error: 'invalid_grant' }),
        ok: true,
      }),
    )
    const app = makeApp()
    const res = await app.request('/auth/callback?code=authcode&state=mystate', {
      headers: { cookie: makeCookieHeader({ oauth_state: 'mystate', pkce_verifier: 'verifier123' }) },
    })
    expect(res.status).toBe(401)
  })
})
