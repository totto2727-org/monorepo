import { Predicate, String } from 'effect'
import type { Context } from 'hono'
import { getCookie } from 'hono/cookie'

import { FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'

export const handleAuthCallback = async (c: Context): Promise<Response> => {
  const code = c.req.query('code')
  const state = c.req.query('state')

  const storedState = getCookie(c, 'oauth_state')
  const verifier = getCookie(c, 'pkce_verifier')

  if (Predicate.isNullish(state) || Predicate.isNullish(storedState) || state !== storedState) {
    return new Response('state mismatch', { status: 403 })
  }

  if (Predicate.isNullish(code) || Predicate.isNullish(verifier)) {
    return new Response('missing code or verifier', { status: 400 })
  }

  const idpBaseUrl = process.env.IDP_BASE_URL ?? 'http://localhost:8787'
  const clientId = process.env.OAUTH_CLIENT_ID ?? 'feed-platform-web'
  const clientSecret = process.env.OAUTH_CLIENT_SECRET ?? ''
  const webBaseUrl = process.env.WEB_BASE_URL ?? 'http://localhost:8788'
  const redirectUri = `${webBaseUrl}/auth/callback`

  const bodyParams: Record<string, string> = {
    client_id: clientId,
    code,
    code_verifier: verifier,
    grant_type: 'authorization_code',
    redirect_uri: redirectUri,
  }
  if (String.isNonEmpty(clientSecret)) {
    bodyParams.client_secret = clientSecret
  }

  const tokenRes = await fetch(`${idpBaseUrl}/api/v1/auth/oauth2/token`, {
    body: new URLSearchParams(bodyParams).toString(),
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    method: 'POST',
  })

  if (!tokenRes.ok) {
    return new Response('auth failed', { status: 401 })
  }

  const tokenJson: unknown = await tokenRes.json()
  if (!Predicate.isObject(tokenJson)) {
    return new Response('auth failed', { status: 401 })
  }

  const accessToken = tokenJson.access_token

  if (!Predicate.isString(accessToken) || String.isEmpty(accessToken)) {
    return new Response('auth failed', { status: 401 })
  }

  const headers = new Headers({ Location: '/dashboard' })
  headers.append('Set-Cookie', `${FEED_SESSION_COOKIE}=${accessToken}; HttpOnly; SameSite=Lax; Path=/`)
  headers.append('Set-Cookie', 'pkce_verifier=; Max-Age=0; Path=/; SameSite=Lax; HttpOnly')
  headers.append('Set-Cookie', 'oauth_state=; Max-Age=0; Path=/; SameSite=Lax; HttpOnly')

  return new Response(null, { headers, status: 302 })
}
