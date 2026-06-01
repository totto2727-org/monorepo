import { Effect } from 'effect'
import { FetchHttpClient } from 'effect/unstable/http'
import { Hono } from 'hono'
import { afterEach, describe, expect, it, vi } from 'vite-plus/test'

import { FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'
import { makeInMemory } from '#@/feature/db/kysely.ts'
import type { Type as EnvType } from '#@/feature/env.ts'

import { handleAuthCallback } from './callback.ts'

const testEnv: EnvType = {
  BACKEND_BASE_URL: 'http://localhost:8789',
  DATABASE_AUTH_TOKEN: '',
  DATABASE_URL: ':memory:',
  IDP_BASE_URL: 'https://idp.example.com',
  OAUTH_CLIENT_ID: 'feed-platform-web',
  OAUTH_CLIENT_SECRET: '',
}

const makeApp = () =>
  new Hono().get('/auth/callback', (ctx) =>
    Effect.runPromise(handleAuthCallback(ctx, testEnv, makeInMemory()).pipe(Effect.provide(FetchHttpClient.layer))),
  )

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
      vi.fn().mockResolvedValue(Response.json({ access_token: 'jwt-token-here' }, { status: 200 })),
    )
    const app = makeApp()
    const res = await app.request('/auth/callback?code=authcode&state=mystate', {
      headers: { cookie: makeCookieHeader({ oauth_state: 'mystate', pkce_verifier: 'verifier123' }) },
    })
    expect(res.status).toBe(302)
    expect(res.headers.get('location')).toBe('/dashboard')
    const cookies = res.headers.getSetCookie()
    expect(cookies.some((cookie) => cookie.startsWith(`${FEED_SESSION_COOKIE}=jwt-token-here`))).toBe(true)
  })

  it('returns 401 when token endpoint returns non-200', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response(null, { status: 401 })))
    const app = makeApp()
    const res = await app.request('/auth/callback?code=authcode&state=mystate', {
      headers: { cookie: makeCookieHeader({ oauth_state: 'mystate', pkce_verifier: 'verifier123' }) },
    })
    expect(res.status).toBe(401)
  })

  it('returns 401 when access_token is missing from response', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(Response.json({})))
    const app = makeApp()
    const res = await app.request('/auth/callback?code=authcode&state=mystate', {
      headers: { cookie: makeCookieHeader({ oauth_state: 'mystate', pkce_verifier: 'verifier123' }) },
    })
    expect(res.status).toBe(401)
  })
})
