import { Effect, Predicate, Schema, String } from 'effect'
import { HttpClient, HttpClientRequest, HttpBody } from 'effect/unstable/http'
import { Hono } from 'hono'
import { remixRenderer } from 'hono-remix-middleware'
import { contextStorage } from 'hono/context-storage'
import { getCookie } from 'hono/cookie'
import { logger } from 'hono/logger'

import { BackendClient, liveLayer } from '#@/feature/api/client.ts'
import { handleAuthCallback } from '#@/feature/auth/callback.ts'
import { FEED_REFRESH_COOKIE, FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'
import { authMiddleware } from '#@/feature/auth/middleware.ts'
import type { AuthUser } from '#@/feature/auth/middleware.ts'
import { storeNonce } from '#@/feature/auth/nonce-store.ts'
import {
  buildAuthorizeUrl,
  generateChallenge,
  generateNonce,
  generateState,
  generateVerifier,
} from '#@/feature/auth/oauth-client.ts'
import { Service as DBService } from '#@/feature/db/kysely.ts'
import type { Type as EnvType } from '#@/feature/env.ts'
import * as Greeting from '#@/feature/greeting.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'
import type { Variables } from '#@/feature/runtime/hono.ts'
import { Document } from '#@/ui/document.tsx'

interface AppEnv {
  Bindings: EnvType
  Variables: Variables & { user: AuthUser | null }
}

const TokenResponse = Schema.Struct({
  access_token: Schema.String,
  refresh_token: Schema.optional(Schema.String),
})

const refreshTokens = (idpBaseUrl: string, params: Record<string, string>) =>
  Effect.gen(function* () {
    const client = yield* HttpClient.HttpClient
    const formBody = new URLSearchParams(params).toString()
    const request = HttpClientRequest.post(`${idpBaseUrl}/api/v1/auth/oauth2/token`, {
      body: HttpBody.text(formBody, 'application/x-www-form-urlencoded'),
    })
    const response = yield* client.execute(request)
    if (response.status !== 200) return yield* Effect.fail(new Error('token refresh failed'))
    const data: unknown = yield* response.json
    return yield* Schema.decodeUnknownEffect(TokenResponse)(data)
  })

const logoutFromIdp = (idpBaseUrl: string, sessionCookieValue: string) =>
  Effect.gen(function* () {
    const client = yield* HttpClient.HttpClient
    const request = HttpClientRequest.post(`${idpBaseUrl}/api/v1/auth/sign-out`, {
      headers: { Cookie: `${FEED_SESSION_COOKIE}=${sessionCookieValue}` },
    })
    yield* client.execute(request)
  })

const redirectToLogin = () => {
  const headers = new Headers({ Location: '/login' })
  headers.append('Set-Cookie', `${FEED_SESSION_COOKIE}=; Max-Age=0; Path=/; SameSite=Lax; HttpOnly`)
  headers.append('Set-Cookie', `${FEED_REFRESH_COOKIE}=; Max-Age=0; Path=/; SameSite=Lax; HttpOnly`)
  return new Response(null, { headers, status: 302 })
}

const app: Hono<AppEnv> = new Hono<AppEnv>()
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
  .get('/login', async (ctx) => {
    const env = ctx.env
    const runtime = ctx.var.runtime

    const verifier = generateVerifier()
    const state = generateState()
    const nonce = generateNonce()
    const codeChallenge = await generateChallenge(verifier)

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

    await runtime.runPromise(
      Effect.gen(function* () {
        const db = yield* DBService
        return yield* Effect.promise(() => storeNonce(db, state, nonce, Date.now()))
      }),
    )

    const headers = new Headers({ Location: authorizeUrl.toString() })
    headers.append('Set-Cookie', `pkce_verifier=${verifier}; HttpOnly; SameSite=Lax; Path=/`)
    headers.append('Set-Cookie', `oauth_state=${state}; HttpOnly; SameSite=Lax; Path=/`)
    return new Response(null, { headers, status: 302 })
  })
  .get('/auth/callback', async (ctx) => {
    const db = await ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        return yield* DBService
      }),
    )
    return handleAuthCallback(ctx, ctx.env, db, ctx.var.runtime)
  })
  .get('/api/me-debug', (ctx) => ctx.json({ user: ctx.var.user }))
  .get('/api/v1/hello', (ctx) =>
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const greeting = yield* Greeting.Service
        return ctx.json({ message: greeting.greet('feed-platform-web') })
      }),
    ),
  )
  .get('/dashboard', async (ctx) => {
    const { runtime, user } = ctx.var
    if (Predicate.isNullish(user)) return ctx.redirect('/login')
    const token = getCookie(ctx, FEED_SESSION_COOKIE)
    const authorization = Predicate.isNullish(token) ? null : `Bearer ${token}`

    const callMeResult = await runtime.runPromise(
      Effect.provide(
        Effect.gen(function* () {
          const client = yield* BackendClient
          return yield* client.callMe(authorization)
        }),
        liveLayer,
      ).pipe(Effect.orElseSucceed(() => null)),
    )
    if (callMeResult !== null) {
      return ctx.render(
        <Document>
          <h1>Dashboard</h1>
          <p>Logged in as: {callMeResult.email}</p>
          <p>User ID: {callMeResult.id}</p>
          <a href='/logout'>Logout</a>
        </Document>,
      )
    }

    const refreshToken = getCookie(ctx, FEED_REFRESH_COOKIE)
    if (Predicate.isNullish(refreshToken)) return redirectToLogin()

    const env = ctx.env
    const bodyParams: Record<string, string> = {
      client_id: env.OAUTH_CLIENT_ID,
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
    }
    if (String.isNonEmpty(env.OAUTH_CLIENT_SECRET)) {
      bodyParams.client_secret = env.OAUTH_CLIENT_SECRET
    }

    const tokenData = await runtime.runPromise(
      refreshTokens(env.IDP_BASE_URL, bodyParams).pipe(Effect.orElseSucceed(() => null)),
    )
    if (tokenData === null) return redirectToLogin()

    const retryResult = await runtime.runPromise(
      Effect.provide(
        Effect.gen(function* () {
          const client = yield* BackendClient
          return yield* client.callMe(`Bearer ${tokenData.access_token}`)
        }),
        liveLayer,
      ).pipe(Effect.orElseSucceed(() => null)),
    )
    if (retryResult === null) return redirectToLogin()

    const responseHeaders = new Headers()
    responseHeaders.append(
      'Set-Cookie',
      `${FEED_SESSION_COOKIE}=${tokenData.access_token}; HttpOnly; SameSite=Lax; Path=/`,
    )
    if (tokenData.refresh_token !== undefined && String.isNonEmpty(tokenData.refresh_token)) {
      responseHeaders.append(
        'Set-Cookie',
        `${FEED_REFRESH_COOKIE}=${tokenData.refresh_token}; HttpOnly; SameSite=Lax; Path=/; Max-Age=2592000`,
      )
    }

    const res = ctx.render(
      <Document>
        <h1>Dashboard</h1>
        <p>Logged in as: {retryResult.email}</p>
        <p>User ID: {retryResult.id}</p>
        <a href='/logout'>Logout</a>
      </Document>,
    )
    for (const [key, value] of responseHeaders) {
      if (key.toLowerCase() === 'set-cookie') res.headers.append(key, value)
    }
    return res
  })
  .get('/logout', async (ctx) => {
    const token = getCookie(ctx, FEED_SESSION_COOKIE)
    if (!Predicate.isNullish(token)) {
      await ctx.var.runtime.runPromise(logoutFromIdp(ctx.env.IDP_BASE_URL, token)).catch(() => null)
    }
    return redirectToLogin()
  })

export default app
