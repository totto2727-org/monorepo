import { DateTime, Effect, Predicate, Schema, String } from 'effect'
import { HttpClient, HttpClientRequest, HttpBody } from 'effect/unstable/http'
import { Hono } from 'hono'
import { remixRenderer } from 'hono-remix-middleware'
import { contextStorage } from 'hono/context-storage'
import { deleteCookie, getCookie, setCookie } from 'hono/cookie'
import { logger } from 'hono/logger'

import { BackendClient } from '#@/feature/api/client.ts'
import { handleAuthCallback } from '#@/feature/auth/callback.ts'
import { FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'
import { authMiddleware } from '#@/feature/auth/middleware.ts'
import { storeNonce } from '#@/feature/auth/nonce-store.ts'
import {
  buildAuthorizeUrl,
  generateChallenge,
  generateNonce,
  generateState,
  generateVerifier,
} from '#@/feature/auth/oauth-client.ts'
import { deleteRefreshToken, getRefreshToken, replaceRefreshToken } from '#@/feature/auth/refresh-store.ts'
import { Service as DBService } from '#@/feature/db/kysely.ts'
import * as AppEnv from '#@/feature/env.ts'
import * as Greeting from '#@/feature/greeting.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'
import type { Env } from '#@/feature/share/lib/hono/context.ts'
import { Document } from '#@/ui/document.tsx'

const TokenResponse = Schema.Struct({
  access_token: Schema.String,
  id_token: Schema.String,
  refresh_token: Schema.optional(Schema.String),
})

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- OAuth token JSON response is an external boundary with unknown shape.
const decodeTokenResponse = Schema.decodeUnknownEffect(TokenResponse)

const refreshTokens = (idpBaseUrl: string, params: Record<string, string>) =>
  Effect.gen(function* () {
    const client = yield* HttpClient.HttpClient
    const formBody = new URLSearchParams(params).toString()
    const request = HttpClientRequest.post(`${idpBaseUrl}/api/v1/auth/oauth2/token`, {
      body: HttpBody.text(formBody, 'application/x-www-form-urlencoded'),
    })
    const response = yield* client.execute(request)
    if (response.status !== 200) {
      return yield* Effect.fail(new Error('token refresh failed'))
    }
    const data: unknown = yield* response.json
    return yield* decodeTokenResponse(data)
  })

const logoutFromIdp = (idpBaseUrl: string, sessionCookieValue: string) =>
  Effect.gen(function* () {
    const client = yield* HttpClient.HttpClient
    const request = HttpClientRequest.post(`${idpBaseUrl}/api/v1/auth/sign-out`, {
      body: HttpBody.jsonUnsafe({}),
      headers: { Cookie: `${FEED_SESSION_COOKIE}=${sessionCookieValue}` },
    })
    yield* client.execute(request)
  })

const app: Hono<Env> = new Hono<Env>()
  .use(logger())
  .use(contextStorage())
  .use(runtimeMiddleware)
  .use('*', authMiddleware)
  .use(
    '*',
    remixRenderer({
      fetcher: (input): Promise<Response> => Promise.resolve(app.fetch(new Request(input))),
    }),
  )
  .get('/', (ctx) =>
    ctx.render(
      <Document>
        <h1>Hello, feed-platform-web</h1>
      </Document>,
    ),
  )
  .get('/login', (ctx) =>
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP handler boundary executes the whole OAuth login workflow once.
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const env = yield* AppEnv.Service
        const verifier = generateVerifier()
        const state = generateState()
        const nonce = generateNonce()
        const codeChallenge = yield* Effect.promise(() => generateChallenge(verifier))
        const { origin } = new URL(ctx.req.url)
        const redirectUri = `${origin}/auth/callback`
        const authorizeUrl = buildAuthorizeUrl({
          clientId: env.OAUTH_CLIENT_ID,
          codeChallenge,
          idpBaseUrl: env.IDP_BASE_URL,
          nonce,
          redirectUri,
          state,
        })
        const db = yield* DBService
        const now = DateTime.toEpochMillis(yield* DateTime.now)
        yield* Effect.promise(() => storeNonce(db, state, nonce, now))
        setCookie(ctx, 'pkce_verifier', verifier, { httpOnly: true, path: '/', sameSite: 'Lax' })
        setCookie(ctx, 'oauth_state', state, { httpOnly: true, path: '/', sameSite: 'Lax' })
        return ctx.redirect(authorizeUrl.toString())
      }),
    ),
  )
  .get('/auth/callback', (ctx) =>
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP callback boundary executes request-scoped callback Effect once.
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const env = yield* AppEnv.Service
        const db = yield* DBService
        return yield* handleAuthCallback(ctx, env, db)
      }),
    ),
  )
  .get('/api/me-debug', (ctx) => ctx.json({ user: ctx.var.user }))
  .get('/api/v1/hello', (ctx) =>
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP handler boundary executes request-scoped greeting Effect.
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const greeting = yield* Greeting.Service
        return ctx.json({ message: greeting.greet('feed-platform-web') })
      }),
    ),
  )
  .get('/dashboard', (ctx) =>
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP handler boundary executes the whole dashboard dependency and render workflow once.
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const { user } = ctx.var
        const sessionToken = getCookie(ctx, FEED_SESSION_COOKIE)
        if (Predicate.isNullish(user) && Predicate.isNullish(sessionToken)) {
          return ctx.redirect('/login')
        }
        const env = yield* AppEnv.Service
        const client = yield* BackendClient
        const callMeResult = Predicate.isNullish(user)
          ? null
          : yield* client.callMe().pipe(Effect.orElseSucceed(() => null))
        if (!Predicate.isNullish(callMeResult)) {
          return ctx.render(
            <Document>
              <h1>Dashboard</h1>
              <p>Logged in as: {callMeResult.email}</p>
              <p>Subject: {callMeResult.sub}</p>
              <a href='/logout'>Logout</a>
            </Document>,
          )
        }

        const db = yield* DBService
        if (Predicate.isNullish(sessionToken)) {
          deleteCookie(ctx, FEED_SESSION_COOKIE, { httpOnly: true, path: '/', sameSite: 'Lax' })
          return ctx.redirect('/login')
        }
        const now = DateTime.toEpochMillis(yield* DateTime.now)
        const refreshToken = yield* Effect.promise(() => getRefreshToken(db, sessionToken, now))
        if (Predicate.isNullish(refreshToken)) {
          deleteCookie(ctx, FEED_SESSION_COOKIE, { httpOnly: true, path: '/', sameSite: 'Lax' })
          return ctx.redirect('/login')
        }

        const bodyParams: Record<string, string> = {
          client_id: env.OAUTH_CLIENT_ID,
          grant_type: 'refresh_token',
          refresh_token: refreshToken,
          resource: env.BACKEND_RESOURCE,
        }
        if (String.isNonEmpty(env.OAUTH_CLIENT_SECRET)) {
          bodyParams.client_secret = env.OAUTH_CLIENT_SECRET
        }

        const tokenData = yield* refreshTokens(env.IDP_BASE_URL, bodyParams).pipe(Effect.orElseSucceed(() => null))
        if (Predicate.isNullish(tokenData)) {
          yield* Effect.promise(() => deleteRefreshToken(db, sessionToken))
          deleteCookie(ctx, FEED_SESSION_COOKIE, { httpOnly: true, path: '/', sameSite: 'Lax' })
          return ctx.redirect('/login')
        }

        const retryResult = yield* client
          .callMeWithAccessToken(tokenData.access_token)
          .pipe(Effect.orElseSucceed(() => null))
        if (Predicate.isNullish(retryResult)) {
          yield* Effect.promise(() => deleteRefreshToken(db, sessionToken))
          deleteCookie(ctx, FEED_SESSION_COOKIE, { httpOnly: true, path: '/', sameSite: 'Lax' })
          return ctx.redirect('/login')
        }

        const nextSessionToken = tokenData.id_token
        setCookie(ctx, FEED_SESSION_COOKIE, nextSessionToken, {
          httpOnly: true,
          path: '/',
          sameSite: 'Lax',
        })
        const nextRefreshToken =
          !Predicate.isNullish(tokenData.refresh_token) && String.isNonEmpty(tokenData.refresh_token)
            ? tokenData.refresh_token
            : refreshToken
        yield* Effect.promise(() =>
          replaceRefreshToken(db, sessionToken, nextSessionToken, nextRefreshToken, tokenData.access_token, now),
        )

        return ctx.render(
          <Document>
            <h1>Dashboard</h1>
            <p>Logged in as: {retryResult.email}</p>
            <p>Subject: {retryResult.sub}</p>
            <a href='/logout'>Logout</a>
          </Document>,
        )
      }),
    ),
  )
  .get('/logout', (ctx) =>
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP handler boundary executes the whole logout workflow once.
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const env = yield* AppEnv.Service
        const db = yield* DBService
        const token = getCookie(ctx, FEED_SESSION_COOKIE)
        if (!Predicate.isNullish(token)) {
          yield* logoutFromIdp(env.IDP_BASE_URL, token).pipe(Effect.ignore)
          yield* Effect.promise(() => deleteRefreshToken(db, token))
        }
        deleteCookie(ctx, FEED_SESSION_COOKIE, { httpOnly: true, path: '/', sameSite: 'Lax' })
        return ctx.redirect('/login')
      }),
    ),
  )

export default app
