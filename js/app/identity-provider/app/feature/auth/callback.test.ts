import { Hono } from 'hono'
import { describe, expect, test, vi } from 'vite-plus/test'

import { handleAuthCallback } from './callback.ts'

type GetSession = (input: { readonly headers: Headers }) => Promise<unknown>

interface MockAuth {
  readonly api: {
    readonly getSession: ReturnType<typeof vi.fn<GetSession>>
  }
}

const makeApp = (auth: MockAuth) => {
  const app = new Hono<{ Variables: { auth: MockAuth } }>()
  app.use('*', async (c, next) => {
    c.set('auth', auth)
    await next()
  })
  app.get('/auth/callback', handleAuthCallback)
  return app
}

describe('/auth/callback', () => {
  test('redirects an established magic-link session to account', async () => {
    const getSession = vi.fn<GetSession>().mockResolvedValue({ session: { id: 'session-id' }, user: { id: 'user-id' } })
    const response = await makeApp({ api: { getSession } }).request('/auth/callback', {
      headers: { cookie: 'better-auth.session_token=session-token' },
    })
    const [input] = getSession.mock.calls[0] ?? []

    expect(input?.headers).toBeInstanceOf(Headers)
    expect(response.status).toBe(302)
    expect(response.headers.get('location')).toBe('/account')
  })

  test('redirects a missing magic-link session to login with invalid_link', async () => {
    const getSession = vi.fn<GetSession>().mockResolvedValue(null)
    const response = await makeApp({ api: { getSession } }).request('/auth/callback')
    const [input] = getSession.mock.calls[0] ?? []

    expect(input?.headers).toBeInstanceOf(Headers)
    expect(response.status).toBe(302)
    expect(response.headers.get('location')).toBe('/login?error=invalid_link')
  })
})
