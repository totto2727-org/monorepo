import { DateTime, Effect, Predicate, Schema, String } from 'effect'
import { HttpClient, HttpClientRequest, HttpBody } from 'effect/unstable/http'
import { Hono } from 'hono'
import { remixRenderer } from 'hono-remix-middleware'
import { contextStorage } from 'hono/context-storage'
import { deleteCookie, getCookie, setCookie } from 'hono/cookie'
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
      headers: { Cookie: `${FEED_SESSION_COOKIE}=${sessionCookieValue}` },
    })
    yield* client.execute(request)
  })

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
    const { env } = ctx
    const { runtime } = ctx.var

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

    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP handler boundary stores OAuth nonce with the request runtime.
    await runtime.runPromise(
      Effect.gen(function* () {
        const db = yield* DBService
        const now = DateTime.toEpochMillis(yield* DateTime.now)
        return yield* Effect.promise(() => storeNonce(db, state, nonce, now))
      }),
    )

    setCookie(ctx, 'pkce_verifier', verifier, { httpOnly: true, path: '/', sameSite: 'Lax' })
    setCookie(ctx, 'oauth_state', state, { httpOnly: true, path: '/', sameSite: 'Lax' })

    return ctx.redirect(authorizeUrl.toString())
  })
  .get('/auth/callback', (ctx) =>
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP callback boundary executes request-scoped callback Effect once.
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const db = yield* DBService
        return yield* handleAuthCallback(ctx, ctx.env, db)
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
  .get('/dashboard', async (ctx) => {
    const { runtime, user } = ctx.var
    if (Predicate.isNullish(user)) {
      return ctx.redirect('/login')
    }
    const token = getCookie(ctx, FEED_SESSION_COOKIE)
    const authorization = Predicate.isNullish(token) ? null : `Bearer ${token}`
    const { env } = ctx

    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP handler boundary executes the whole dashboard dependency workflow once.
    const dashboardResult = await runtime.runPromise(
      Effect.provide(
        Effect.gen(function* () {
          const client = yield* BackendClient
          const callMeResult = yield* client.callMe(authorization).pipe(Effect.orElseSucceed(() => null))
          if (!Predicate.isNullish(callMeResult)) {
            return { _tag: 'authenticated', user: callMeResult } as const
          }

          const refreshToken = getCookie(ctx, FEED_REFRESH_COOKIE)
          if (Predicate.isNullish(refreshToken)) {
            return { _tag: 'redirect' } as const
          }

          const bodyParams: Record<string, string> = {
            client_id: env.OAUTH_CLIENT_ID,
            grant_type: 'refresh_token',
            refresh_token: refreshToken,
          }
          if (String.isNonEmpty(env.OAUTH_CLIENT_SECRET)) {
            bodyParams.client_secret = env.OAUTH_CLIENT_SECRET
          }

          const tokenData = yield* refreshTokens(env.IDP_BASE_URL, bodyParams).pipe(Effect.orElseSucceed(() => null))
          if (Predicate.isNullish(tokenData)) {
            return { _tag: 'redirect' } as const
          }

          const retryResult = yield* client
            .callMe(`Bearer ${tokenData.access_token}`)
            .pipe(Effect.orElseSucceed(() => null))
          if (Predicate.isNullish(retryResult)) {
            return { _tag: 'redirect' } as const
          }

          return { _tag: 'refreshed', tokenData, user: retryResult } as const
        }),
        liveLayer,
      ),
    )

    if (dashboardResult._tag === 'authenticated') {
      return ctx.render(
        <Document>
          <h1>Dashboard</h1>
          <p>Logged in as: {dashboardResult.user.email}</p>
          <p>User ID: {dashboardResult.user.id}</p>
          <a href='/logout'>Logout</a>
        </Document>,
      )
    }

    if (dashboardResult._tag === 'redirect') {
      deleteCookie(ctx, FEED_SESSION_COOKIE, { httpOnly: true, path: '/', sameSite: 'Lax' })
      deleteCookie(ctx, FEED_REFRESH_COOKIE, { httpOnly: true, path: '/', sameSite: 'Lax' })
      return ctx.redirect('/login')
    }

    setCookie(ctx, FEED_SESSION_COOKIE, dashboardResult.tokenData.access_token, {
      httpOnly: true,
      path: '/',
      sameSite: 'Lax',
    })
    if (
      !Predicate.isNullish(dashboardResult.tokenData.refresh_token) &&
      String.isNonEmpty(dashboardResult.tokenData.refresh_token)
    ) {
      setCookie(ctx, FEED_REFRESH_COOKIE, dashboardResult.tokenData.refresh_token, {
        httpOnly: true,
        maxAge: 2_592_000,
        path: '/',
        sameSite: 'Lax',
      })
    }

    return ctx.render(
      <Document>
        <h1>Dashboard</h1>
        <p>Logged in as: {dashboardResult.user.email}</p>
        <p>User ID: {dashboardResult.user.id}</p>
        <a href='/logout'>Logout</a>
      </Document>,
    )
  })
  .get('/logout', async (ctx) => {
    const token = getCookie(ctx, FEED_SESSION_COOKIE)
    if (!Predicate.isNullish(token)) {
      // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP handler boundary best-effort signs out from IdP through the request runtime.
      await ctx.var.runtime.runPromise(logoutFromIdp(ctx.env.IDP_BASE_URL, token)).catch(() => null)
    }
    deleteCookie(ctx, FEED_SESSION_COOKIE, { httpOnly: true, path: '/', sameSite: 'Lax' })
    deleteCookie(ctx, FEED_REFRESH_COOKIE, { httpOnly: true, path: '/', sameSite: 'Lax' })
    return ctx.redirect('/login')
  })

export default app
