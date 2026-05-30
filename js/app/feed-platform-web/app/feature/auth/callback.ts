import { Effect, Predicate, Schema, String } from 'effect'
import { HttpClient, HttpClientRequest, HttpBody } from 'effect/unstable/http'
import type { Context } from 'hono'
import { deleteCookie, getCookie, setCookie } from 'hono/cookie'

import { FEED_REFRESH_COOKIE, FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'
import { verifyAndDeleteNonce } from '#@/feature/auth/nonce-store.ts'
import type { Instance as DBInstance } from '#@/feature/db/kysely.ts'
import * as Env from '#@/feature/env.ts'

const TokenResponse = Schema.Struct({
  access_token: Schema.String,
  id_token: Schema.optional(Schema.String),
  refresh_token: Schema.optional(Schema.String),
})

const decodeTokenResponse = Schema.decodeUnknownEffect(TokenResponse)

const exchangeToken = (idpBaseUrl: string, params: Record<string, string>) =>
  Effect.gen(function* () {
    const client = yield* HttpClient.HttpClient
    const formBody = new URLSearchParams(params).toString()
    const request = HttpClientRequest.post(`${idpBaseUrl}/api/v1/auth/oauth2/token`, {
      body: HttpBody.text(formBody, 'application/x-www-form-urlencoded'),
    })
    const response = yield* client.execute(request)
    if (response.status !== 200) return yield* Effect.fail(new Error('token exchange failed'))
    const data: unknown = yield* response.json
    return data
  })

const verifyNonce = (db: DBInstance, idToken: string, state: string) =>
  Effect.gen(function* () {
    const parts = idToken.split('.')
    if (parts.length !== 3) return false
    const [, payloadPart] = parts
    if (Predicate.isUndefined(payloadPart)) return false
    const payloadStr = atob(payloadPart)
    const payload = JSON.parse(payloadStr)
    if (!Predicate.isObject(payload)) return false
    if (!('nonce' in payload)) return false
    const { nonce } = payload
    if (!Predicate.isString(nonce)) return false
    return yield* Effect.promise(() => verifyAndDeleteNonce(db, state, nonce))
  })

export interface CallbackRuntime {
  readonly runPromise: <A, E>(effect: Effect.Effect<A, E, never>) => Promise<A>
}

export const handleAuthCallback = async (
  ctx: Context,
  env: Env.Type,
  db: DBInstance,
  callbackRuntime: CallbackRuntime,
): Promise<Response> => {
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
  }
  if (String.isNonEmpty(env.OAUTH_CLIENT_SECRET)) {
    bodyParams.client_secret = env.OAUTH_CLIENT_SECRET
  }

  const result = await callbackRuntime
    .runPromise(
      Effect.gen(function* () {
        const rawToken = yield* exchangeToken(env.IDP_BASE_URL, bodyParams)
        return yield* decodeTokenResponse(rawToken)
      }),
    )
    .catch(() => null)

  if (Predicate.isNull(result)) return new Response('auth failed', { status: 401 })
  if (String.isEmpty(result.access_token)) return new Response('auth failed', { status: 401 })

  if (!Predicate.isUndefined(result.id_token) && Predicate.isNotNullish(state)) {
    const valid = await callbackRuntime.runPromise(verifyNonce(db, result.id_token, state))
    if (!valid) return new Response('nonce mismatch', { status: 403 })
  }

  setCookie(ctx, FEED_SESSION_COOKIE, result.access_token, { httpOnly: true, path: '/', sameSite: 'Lax' })
  deleteCookie(ctx, 'pkce_verifier', { httpOnly: true, path: '/', sameSite: 'Lax' })
  deleteCookie(ctx, 'oauth_state', { httpOnly: true, path: '/', sameSite: 'Lax' })

  if (!Predicate.isUndefined(result.refresh_token) && String.isNonEmpty(result.refresh_token)) {
    setCookie(ctx, FEED_REFRESH_COOKIE, result.refresh_token, {
      httpOnly: true,
      maxAge: 2592000,
      path: '/',
      sameSite: 'Lax',
    })
  }

  return ctx.redirect('/dashboard')
}
