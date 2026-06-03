import { DateTime, Effect, Predicate, Schema, String } from 'effect'
import { HttpBody, HttpClient, HttpClientRequest } from 'effect/unstable/http'
import type { Context } from 'hono'
import { deleteCookie, getCookie, setCookie } from 'hono/cookie'

import { FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'
import { verifyAndDeleteNonce } from '#@/feature/auth/nonce-store.ts'
import { storeRefreshToken } from '#@/feature/auth/refresh-store.ts'
import type { Instance as DBInstance } from '#@/feature/db/kysely.ts'
import type * as Env from '#@/feature/env.ts'

const TokenResponse = Schema.Struct({
  access_token: Schema.String,
  id_token: Schema.optional(Schema.String),
  refresh_token: Schema.optional(Schema.String),
})

const IdTokenPayload = Schema.Struct({
  nonce: Schema.String,
})

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- OAuth token JSON response is an external boundary with unknown shape.
const decodeTokenResponse = Schema.decodeUnknownEffect(TokenResponse)
// oxlint-disable-next-line rules/prefer-non-unknown-decode -- ID token payload JSON is decoded from an untrusted token segment.
const decodeIdTokenPayload = Schema.decodeUnknownEffect(IdTokenPayload)

const exchangeToken = (idpBaseUrl: string, params: Record<string, string>) =>
  Effect.gen(function* () {
    const client = yield* HttpClient.HttpClient
    const formBody = new URLSearchParams(params).toString()
    const request = HttpClientRequest.post(`${idpBaseUrl}/api/v1/auth/oauth2/token`, {
      body: HttpBody.text(formBody, 'application/x-www-form-urlencoded'),
    })
    const response = yield* client.execute(request)
    if (response.status !== 200) {
      const text = yield* response.text
      return { data: null, error: String.isNonEmpty(text) ? text : 'token exchange failed' }
    }
    const data: unknown = yield* response.json
    return { data, error: null }
  })

const verifyNonce = (db: DBInstance, idToken: string, state: string) =>
  Effect.gen(function* () {
    const parts = idToken.split('.')
    if (parts.length !== 3) {
      return false
    }
    const [, payloadPart] = parts
    if (Predicate.isNullish(payloadPart)) {
      return false
    }
    const payloadStr = atob(payloadPart)
    const payload: unknown = JSON.parse(payloadStr)
    const decodedPayload = yield* decodeIdTokenPayload(payload).pipe(Effect.orElseSucceed(() => null))
    if (Predicate.isNullish(decodedPayload)) {
      return false
    }
    return yield* Effect.promise(() => verifyAndDeleteNonce(db, state, decodedPayload.nonce))
  })

export const handleAuthCallback = (
  ctx: Context,
  env: Env.Type,
  db: DBInstance,
): Effect.Effect<Response, never, HttpClient.HttpClient> =>
  Effect.gen(function* () {
    const code = ctx.req.query('code')
    const state = ctx.req.query('state')
    const storedState = getCookie(ctx, 'oauth_state')
    const verifier = getCookie(ctx, 'pkce_verifier')

    if (Predicate.isNullish(state) || Predicate.isNullish(storedState) || state !== storedState) {
      return new Response('state mismatch', { status: 403 })
    }
    if (Predicate.isNullish(code) || Predicate.isNullish(verifier)) {
      return new Response('missing code or verifier', { status: 400 })
    }

    const { origin } = new URL(ctx.req.url)
    const redirectUri = `${origin}/auth/callback`
    const bodyParams: Record<string, string> = {
      client_id: env.OAUTH_CLIENT_ID,
      code,
      code_verifier: verifier,
      grant_type: 'authorization_code',
      redirect_uri: redirectUri,
      resource: env.BACKEND_RESOURCE,
    }
    if (String.isNonEmpty(env.OAUTH_CLIENT_SECRET)) {
      bodyParams.client_secret = env.OAUTH_CLIENT_SECRET
    }

    const rawTokenResult = yield* exchangeToken(env.IDP_BASE_URL, bodyParams).pipe(
      Effect.orElseSucceed(() => ({ data: null, error: 'token exchange failed' })),
    )
    if (Predicate.isNullish(rawTokenResult.data)) {
      return new Response(`auth failed: ${rawTokenResult.error}`, { status: 401 })
    }
    const rawToken = rawTokenResult.data
    const result = yield* decodeTokenResponse(rawToken).pipe(Effect.orElseSucceed(() => null))

    if (Predicate.isNullish(result)) {
      return new Response('auth failed', { status: 401 })
    }
    if (String.isEmpty(result.access_token)) {
      return new Response('auth failed', { status: 401 })
    }

    const idToken = result.id_token
    if (Predicate.isNullish(idToken) || String.isEmpty(idToken)) {
      return new Response('auth failed', { status: 401 })
    }

    if (Predicate.isNotNullish(state)) {
      const valid = yield* verifyNonce(db, idToken, state)
      if (!valid) {
        return new Response('nonce mismatch', { status: 403 })
      }
    }

    const sessionToken = idToken
    setCookie(ctx, FEED_SESSION_COOKIE, sessionToken, {
      httpOnly: true,
      path: '/',
      sameSite: 'Lax',
    })
    deleteCookie(ctx, 'pkce_verifier', { httpOnly: true, path: '/', sameSite: 'Lax' })
    deleteCookie(ctx, 'oauth_state', { httpOnly: true, path: '/', sameSite: 'Lax' })

    const refreshToken = result.refresh_token
    if (!Predicate.isNullish(refreshToken) && String.isNonEmpty(refreshToken)) {
      const now = DateTime.toEpochMillis(yield* DateTime.now)
      yield* Effect.promise(() => storeRefreshToken(db, sessionToken, refreshToken, result.access_token, now))
    }

    return ctx.redirect('/dashboard')
  })
