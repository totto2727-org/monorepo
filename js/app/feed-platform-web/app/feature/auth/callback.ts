import { Predicate, String } from 'effect'
import type { Context } from 'hono'
import { getCookie } from 'hono/cookie'

import { FEED_REFRESH_COOKIE, FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'
import { verifyAndDeleteNonce } from '#@/feature/auth/nonce-store.ts'
import type { Instance as DBInstance } from '#@/feature/db/kysely.ts'

interface TokenBody {
  client_id: string
  code: string
  code_verifier: string
  client_secret?: string
  grant_type: string
  redirect_uri: string
}

const exchangeToken = async (idpBaseUrl: string, body: TokenBody): Promise<Record<string, unknown> | null> => {
  const params: Record<string, string> = {
    client_id: body.client_id,
    code: body.code,
    code_verifier: body.code_verifier,
    grant_type: body.grant_type,
    redirect_uri: body.redirect_uri,
  }
  if (String.isNonEmpty(body.client_secret ?? '')) {
    // oxlint-disable-next-line typescript-eslint/no-non-null-assertion -- guarded by isNonEmpty above
    params.client_secret = body.client_secret!
  }

  // oxlint-disable-next-line rules/no-fetch -- external OAuth 2.1 token endpoint
  const res = await fetch(`${idpBaseUrl}/api/v1/auth/oauth2/token`, {
    body: new URLSearchParams(params).toString(),
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    method: 'POST',
  })
  if (!res.ok) {
    return null
  }

  const data: unknown = await res.json()
  // oxlint-disable-next-line rules/prefer-is-nullish -- Predicate.isObject handles nullish check
  if (!Predicate.isObject(data)) {
    return null
  }

  return data
}

const verifyNonce = async (
  db: DBInstance,
  idToken: string | undefined,
  state: string,
): Promise<{ ok: boolean; error?: Response }> => {
  // oxlint-disable-next-line rules/prefer-is-nullish -- Predicate.isString handles null/undefined
  if (!Predicate.isString(idToken)) {
    return { ok: true }
  }

  const parts = idToken.split('.')
  // oxlint-disable-next-line rules/prefer-is-nullish -- string split length check, not nullish comparison
  if (parts.length !== 3) {
    return { error: new Response('invalid id_token', { status: 400 }), ok: false }
  }
  const [, payloadPart] = parts
  // oxlint-disable-next-line rules/prefer-is-nullish -- destructuring gives string | undefined, only undefined needed
  if (Predicate.isUndefined(payloadPart)) {
    return { error: new Response('invalid id_token', { status: 400 }), ok: false }
  }
  // oxlint-disable-next-line typescript-eslint/no-unsafe-type-assertion -- JWT payload decode
  const idTokenPayload = JSON.parse(atob(payloadPart)) as Record<string, unknown>

  // oxlint-disable-next-line typescript-eslint/no-unsafe-type-assertion -- OIDC nonce claim
  const valid = await verifyAndDeleteNonce(db, state, idTokenPayload.nonce as string)
  if (!valid) {
    return { error: new Response('nonce mismatch', { status: 403 }), ok: false }
  }

  return { ok: true }
}

export const handleAuthCallback = async (c: Context): Promise<Response> => {
  // oxlint-disable-next-line typescript-eslint/no-unsafe-type-assertion -- Hono Context extraction
  const { db } = c.var as unknown as { db: DBInstance }
  const code = c.req.query('code')
  const state = c.req.query('state')

  const storedState = getCookie(c, 'oauth_state')
  const verifier = getCookie(c, 'pkce_verifier')

  // oxlint-disable-next-line rules/prefer-is-nullish -- Predicate.isNullish already handles null/undefined checking
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

  const tokenJson = await exchangeToken(idpBaseUrl, {
    client_id: clientId,
    client_secret: clientSecret,
    code,
    code_verifier: verifier,
    grant_type: 'authorization_code',
    redirect_uri: redirectUri,
  })
  // oxlint-disable-next-line rules/force-predicate -- null from exchangeToken means auth failure
  if (tokenJson === null) {
    return new Response('auth failed', { status: 401 })
  }

  const accessToken = tokenJson.access_token
  // oxlint-disable-next-line rules/prefer-is-nullish -- Predicate.isString and String.isEmpty handle null/undefined
  if (!Predicate.isString(accessToken) || String.isEmpty(accessToken)) {
    return new Response('auth failed', { status: 401 })
  }

  // oxlint-disable-next-line typescript-eslint/no-unsafe-type-assertion -- token JSON type extraction
  const nonceResult = await verifyNonce(db, tokenJson.id_token as string | undefined, state)
  // oxlint-disable-next-line rules/prefer-is-nullish -- boolean field, not nullable
  if (!nonceResult.ok) {
    // oxlint-disable-next-line typescript-eslint/no-non-null-assertion -- error is set when ok is false
    return nonceResult.error!
  }

  const headers = new Headers({ Location: '/dashboard' })
  headers.append('Set-Cookie', `${FEED_SESSION_COOKIE}=${accessToken}; HttpOnly; SameSite=Lax; Path=/`)
  headers.append('Set-Cookie', 'pkce_verifier=; Max-Age=0; Path=/; SameSite=Lax; HttpOnly')
  headers.append('Set-Cookie', 'oauth_state=; Max-Age=0; Path=/; SameSite=Lax; HttpOnly')

  const refreshToken = tokenJson.refresh_token
  if (Predicate.isString(refreshToken) && String.isNonEmpty(refreshToken)) {
    headers.append(
      'Set-Cookie',
      `${FEED_REFRESH_COOKIE}=${refreshToken}; HttpOnly; SameSite=Lax; Path=/; Max-Age=2592000`,
    )
  }

  return new Response(null, { headers, status: 302 })
}
