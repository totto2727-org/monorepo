import { Effect, Predicate, Schema, String } from 'effect'
import { FetchHttpClient, HttpClient, HttpClientRequest, HttpBody } from 'effect/unstable/http'
import type { Context } from 'hono'
import { deleteCookie, getCookie, setCookie } from 'hono/cookie'

import { FEED_REFRESH_COOKIE, FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'
import { verifyAndDeleteNonce } from '#@/feature/auth/nonce-store.ts'
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
      return yield* Effect.fail(new Error('token exchange failed'))
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

export interface CallbackRuntime {
  readonly runPromise: <A, E>(effect: Effect.Effect<A, E>) => Promise<A>
}

export const handleAuthCallback = async (
  ctx: Context,
  env: Env.Type,
  db: DBInstance | null,
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

  // oxlint-disable-next-line rules/no-effect-runtime-run -- Hono callback handler boundary executes token exchange Effect.
  const result = await callbackRuntime
    .runPromise(
      Effect.gen(function* () {
        const rawToken = yield* exchangeToken(env.IDP_BASE_URL, bodyParams)
        return yield* decodeTokenResponse(rawToken)
      }).pipe(Effect.provide(FetchHttpClient.layer)),
    )
    .catch(() => null)

  if (Predicate.isNullish(result)) {
    return new Response('auth failed', { status: 401 })
  }
  if (String.isEmpty(result.access_token)) {
    return new Response('auth failed', { status: 401 })
  }

  if (!Predicate.isNullish(result.id_token) && Predicate.isNotNullish(state) && Predicate.isNotNullish(db)) {
    // oxlint-disable-next-line rules/no-effect-runtime-run -- Hono callback handler boundary verifies nonce through the request runtime.
    const valid = await callbackRuntime.runPromise(verifyNonce(db, result.id_token, state))
    if (!valid) {
      return new Response('nonce mismatch', { status: 403 })
    }
  }

  setCookie(ctx, FEED_SESSION_COOKIE, result.access_token, { httpOnly: true, path: '/', sameSite: 'Lax' })
  deleteCookie(ctx, 'pkce_verifier', { httpOnly: true, path: '/', sameSite: 'Lax' })
  deleteCookie(ctx, 'oauth_state', { httpOnly: true, path: '/', sameSite: 'Lax' })

  if (!Predicate.isNullish(result.refresh_token) && String.isNonEmpty(result.refresh_token)) {
    setCookie(ctx, FEED_REFRESH_COOKIE, result.refresh_token, {
      httpOnly: true,
      maxAge: 2_592_000,
      path: '/',
      sameSite: 'Lax',
    })
  }

  return ctx.redirect('/dashboard')
}
