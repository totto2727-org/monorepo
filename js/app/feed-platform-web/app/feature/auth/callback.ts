import { Effect, Predicate, Schema, String } from 'effect'
import type { Context } from 'hono'
import { getCookie } from 'hono/cookie'
import { HttpClient, HttpClientRequest, HttpBody } from 'effect/unstable/http'

import { FEED_REFRESH_COOKIE, FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'
import * as Env from '#@/feature/env.ts'
import { verifyAndDeleteNonce } from '#@/feature/auth/nonce-store.ts'
import type { Instance as DBInstance } from '#@/feature/db/kysely.ts'

const TokenResponse = Schema.Struct({
  access_token: Schema.String,
  id_token: Schema.optional(Schema.String),
  refresh_token: Schema.optional(Schema.String),
})

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
    if (payloadPart === undefined) return false
    const payloadStr = atob(payloadPart)
    const payload = JSON.parse(payloadStr)
    if (!Predicate.isObject(payload)) return false
    if (!('nonce' in payload)) return false
    const nonce = payload.nonce
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

  const redirectUri = `${env.WEB_BASE_URL}/auth/callback`
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

  const rawToken = await callbackRuntime.runPromise(exchangeToken(env.IDP_BASE_URL, bodyParams)).catch(() => null)
  if (rawToken === null) return new Response('auth failed', { status: 401 })

  const token = Schema.decodeUnknownSync(TokenResponse)(rawToken)
  if (String.isEmpty(token.access_token)) return new Response('auth failed', { status: 401 })

  if (token.id_token !== undefined && Predicate.isNotNullish(state)) {
    const valid = await callbackRuntime.runPromise(verifyNonce(db, token.id_token, state))
    if (!valid) return new Response('nonce mismatch', { status: 403 })
  }

  const headers = new Headers({ Location: '/dashboard' })
  headers.append('Set-Cookie', `${FEED_SESSION_COOKIE}=${token.access_token}; HttpOnly; SameSite=Lax; Path=/`)
  headers.append('Set-Cookie', 'pkce_verifier=; Max-Age=0; Path=/; SameSite=Lax; HttpOnly`)
  headers.append('Set-Cookie', 'oauth_state=; Max-Age=0; Path=/; SameSite=Lax; HttpOnly`)

  if (token.refresh_token !== undefined && String.isNonEmpty(token.refresh_token)) {
    headers.append(
      'Set-Cookie',
      `${FEED_REFRESH_COOKIE}=${token.refresh_token}; HttpOnly; SameSite=Lax; Path=/; Max-Age=2592000`,
    )
  }

  return new Response(null, { headers, status: 302 })
}

export const handleAuthCallback = async (
  ctx: Context,
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
  if (String.isNonEmpty(clientSecret)) bodyParams.client_secret = clientSecret

  const rawToken = await callbackRuntime.runPromise(exchangeToken(idpBaseUrl, bodyParams)).catch(() => null)
  if (rawToken === null) return new Response('auth failed', { status: 401 })

  const token = Schema.decodeUnknownSync(TokenResponse)(rawToken)
  if (String.isEmpty(token.access_token)) return new Response('auth failed', { status: 401 })

  if (token.id_token !== undefined && Predicate.isNotNullish(state)) {
    const valid = await callbackRuntime.runPromise(verifyNonce(db, token.id_token, state))
    if (!valid) return new Response('nonce mismatch', { status: 403 })
  }

  const headers = new Headers({ Location: '/dashboard' })
  headers.append('Set-Cookie', `${FEED_SESSION_COOKIE}=${token.access_token}; HttpOnly; SameSite=Lax; Path=/`)
  headers.append('Set-Cookie', 'pkce_verifier=; Max-Age=0; Path=/; SameSite=Lax; HttpOnly')
  headers.append('Set-Cookie', 'oauth_state=; Max-Age=0; Path=/; SameSite=Lax; HttpOnly')

  if (token.refresh_token !== undefined && String.isNonEmpty(token.refresh_token)) {
    headers.append(
      'Set-Cookie',
      `${FEED_REFRESH_COOKIE}=${token.refresh_token}; HttpOnly; SameSite=Lax; Path=/; Max-Age=2592000`,
    )
  }

  return new Response(null, { headers, status: 302 })
}
    const data: unknown = yield* response.json
    return data
  })

const verifyNonce = (db: DBInstance, idToken: string, state: string) =>
  Effect.gen(function* () {
    const parts = idToken.split('.')
    if (parts.length !== 3) {
      return false
    }
    const [, payloadPart] = parts
    if (payloadPart === undefined) {
      return false
    }

    const payloadStr = atob(payloadPart)
    const payload = JSON.parse(payloadStr)
    if (!Predicate.isRecord(payload)) {
      return false
    }

    const { nonce } = payload
    if (!Predicate.isString(nonce)) {
      return false
    }

    return yield* Effect.promise(() => verifyAndDeleteNonce(db, state, nonce))
  })

export interface CallbackRuntime {
  readonly runPromise: <A, E>(effect: Effect.Effect<A, E>) => Promise<A>
}

export const handleAuthCallback = async (
  ctx: Context,
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

  const rawToken = await callbackRuntime.runPromise(exchangeToken(idpBaseUrl, bodyParams)).catch(() => null)
  if (rawToken === null) {
    return new Response('auth failed', { status: 401 })
  }

  const tokenResult = Schema.decodeUnknownSync(TokenResponse)(rawToken)
  if (Either.isLeft(tokenResult)) {
    return new Response('auth failed', { status: 401 })
  }

  const token = tokenResult.right
  if (String.isEmpty(token.access_token)) {
    return new Response('auth failed', { status: 401 })
  }

  if (token.id_token !== undefined && Predicate.isNotNullish(state)) {
    const valid = await callbackRuntime.runPromise(verifyNonce(db, token.id_token, state))
    if (!valid) {
      return new Response('nonce mismatch', { status: 403 })
    }
  }

  const headers = new Headers({ Location: '/dashboard' })
  headers.append('Set-Cookie', `${FEED_SESSION_COOKIE}=${token.access_token}; HttpOnly; SameSite=Lax; Path=/`)
  headers.append('Set-Cookie', 'pkce_verifier=; Max-Age=0; Path=/; SameSite=Lax; HttpOnly')
  headers.append('Set-Cookie', 'oauth_state=; Max-Age=0; Path=/; SameSite=Lax; HttpOnly')

  if (token.refresh_token !== undefined && String.isNonEmpty(token.refresh_token)) {
    headers.append(
      'Set-Cookie',
      `${FEED_REFRESH_COOKIE}=${token.refresh_token}; HttpOnly; SameSite=Lax; Path=/; Max-Age=2592000`,
    )
  }

  return new Response(null, { headers, status: 302 })
}
