import { Effect, Predicate, String } from 'effect'
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
import type { Instance as DBInstance } from '#@/feature/db/kysely.ts'
import * as Greeting from '#@/feature/greeting.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'
import type { Variables } from '#@/feature/runtime/hono.ts'
import { Document } from '#@/ui/document.tsx'

interface AppEnv {
  Variables: Variables & { user: AuthUser | null }
}

interface DashboardUser {
  email: string
  id: string
}

interface RefreshResult {
  accessToken: string
  refreshToken: string | undefined
  user: DashboardUser
}

const callBackend = (authorization: string | null) =>
  Effect.provide(
    Effect.gen(function* () {
      const client = yield* BackendClient
      return yield* client.callMe(authorization)
    }),
    liveLayer,
  )

interface TokenData {
  accessToken: string
  refreshToken: string | null
}

const parseTokenResponse = (data: unknown): TokenData | null => {
  if (!Predicate.isObject(data) || !Predicate.isString(data.access_token)) {
    return null
  }
  const rt = data.refresh_token
  return {
    accessToken: data.access_token,
    refreshToken: Predicate.isString(rt) ? rt : null,
  }
}

const fetchToken = async (idpBaseUrl: string, bodyParams: Record<string, string>): Promise<TokenData | null> => {
  // oxlint-disable-next-line rules/no-fetch -- external IdP token endpoint
  const res = await fetch(`${idpBaseUrl}/api/v1/auth/oauth2/token`, {
    body: new URLSearchParams(bodyParams).toString(),
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    method: 'POST',
  })
  if (!res.ok) {
    return null
  }
  return parseTokenResponse(await res.json())
}

const tryRefresh = async (
  refreshToken: string,
  idpBaseUrl: string,
  clientId: string,
  clientSecret: string,
): Promise<RefreshResult | null> => {
  const bodyParams: Record<string, string> = {
    client_id: clientId,
    grant_type: 'refresh_token',
    refresh_token: refreshToken,
  }
  if (String.isNonEmpty(clientSecret)) {
    bodyParams.client_secret = clientSecret
  }

  const tokenData = await fetchToken(idpBaseUrl, bodyParams)
  // oxlint-disable-next-line rules/prefer-is-nullish -- precise null check, TokenData | null union
  if (Predicate.isNull(tokenData)) {
    return null
  }

  const retryResult = await Effect.runPromise(callBackend(`Bearer ${tokenData.accessToken}`)).catch(() => null)
  // oxlint-disable-next-line rules/force-predicate -- Promise rejection yields null, intentional distinction
  if (retryResult === null) {
    return null
  }

  return {
    accessToken: tokenData.accessToken,
    refreshToken: tokenData.refreshToken ?? undefined,
    user: retryResult,
  }
}

const redirectToLogin = () => {
  const headers = new Headers({ Location: '/login' })
  headers.append('Set-Cookie', `${FEED_SESSION_COOKIE}=; Max-Age=0; Path=/; SameSite=Lax; HttpOnly`)
  headers.append('Set-Cookie', `${FEED_REFRESH_COOKIE}=; Max-Age=0; Path=/; SameSite=Lax; HttpOnly`)
  return new Response(null, { headers, status: 302 })
}

const setCookieHeader = (headers: Headers, name: string, value: string, maxAge?: number): void => {
  const maxAgeSuffix = Predicate.isNotNullish(maxAge) ? `; Max-Age=${maxAge}` : ''
  headers.append('Set-Cookie', `${name}=${value}; HttpOnly; SameSite=Lax; Path=/${maxAgeSuffix}`)
}

const app: Hono<AppEnv> = new Hono<AppEnv>()
  .use(logger())
  .use(contextStorage())
  .use(runtimeMiddleware)
  .use('*', authMiddleware)
  .use(
    '*',
    remixRenderer({
      fetcher: (input): Promise<Response> =>
        Promise.resolve(app.fetch(input instanceof Request ? input : new Request(input))),
    }),
  )
  .get('/', (c) =>
    c.render(
      <Document>
        <h1>Hello, feed-platform-web</h1>
      </Document>,
    ),
  )
  .get('/login', async (c) => {
    const idpBaseUrl = process.env.IDP_BASE_URL ?? 'http://localhost:8787'
    const clientId = process.env.OAUTH_CLIENT_ID ?? 'feed-platform-web'
    const webBaseUrl = process.env.WEB_BASE_URL ?? 'http://localhost:8788'

    const verifier = generateVerifier()
    const state = generateState()
    const nonce = generateNonce()
    const codeChallenge = await generateChallenge(verifier)

    const redirectUri = `${webBaseUrl}/auth/callback`
    const authorizeUrl = buildAuthorizeUrl({
      clientId,
      codeChallenge,
      idpBaseUrl,
      nonce,
      redirectUri,
      state,
    })

    // oxlint-disable-next-line typescript-eslint/no-unsafe-type-assertion -- Hono Context extraction pattern
    const { db } = c.var as unknown as { db: DBInstance }
    await storeNonce(db, state, nonce)

    const headers = new Headers({ Location: authorizeUrl.toString() })
    headers.append('Set-Cookie', `pkce_verifier=${verifier}; HttpOnly; SameSite=Lax; Path=/`)
    headers.append('Set-Cookie', `oauth_state=${state}; HttpOnly; SameSite=Lax; Path=/`)

    return new Response(null, { headers, status: 302 })
  })
  .get('/auth/callback', (c) => handleAuthCallback(c))
  .get('/api/me-debug', (c) => c.json({ user: c.var.user }))
  .get('/api/v1/hello', (c) =>
    c.var.runtime.runPromise(
      Effect.gen(function* () {
        const greeting = yield* Greeting.Service
        return c.json({ message: greeting.greet('feed-platform-web') })
      }),
    ),
  )
  .get('/dashboard', async (c) => {
    const { user } = c.var
    if (Predicate.isNullish(user)) {
      return c.redirect('/login')
    }
    const token = getCookie(c, FEED_SESSION_COOKIE)
    const authorization = Predicate.isNullish(token) ? null : `Bearer ${token}`

    const callMeResult = await Effect.runPromise(callBackend(authorization)).catch(() => null)

    // oxlint-disable-next-line rules/prefer-is-nullish -- precise null check for .catch(() => null) guard
    if (!Predicate.isNull(callMeResult)) {
      return c.render(
        <Document>
          <h1>Dashboard</h1>
          <p>Logged in as: {callMeResult.email}</p>
          <p>User ID: {callMeResult.id}</p>
          <a href='/logout'>Logout</a>
        </Document>,
      )
    }

    const refreshToken = getCookie(c, FEED_REFRESH_COOKIE)
    if (Predicate.isNullish(refreshToken)) {
      return redirectToLogin()
    }

    const idpBaseUrl = process.env.IDP_BASE_URL ?? 'http://localhost:8787'
    const clientId = process.env.OAUTH_CLIENT_ID ?? 'feed-platform-web'
    const clientSecret = process.env.OAUTH_CLIENT_SECRET ?? ''

    const fresh = await tryRefresh(refreshToken, idpBaseUrl, clientId, clientSecret)
    // oxlint-disable-next-line rules/prefer-is-nullish -- precise null check for RefreshResult | null
    if (Predicate.isNull(fresh)) {
      return redirectToLogin()
    }

    const responseHeaders = new Headers()
    setCookieHeader(responseHeaders, FEED_SESSION_COOKIE, fresh.accessToken)
    if (Predicate.isNotNullish(fresh.refreshToken) && String.isNonEmpty(fresh.refreshToken)) {
      setCookieHeader(responseHeaders, FEED_REFRESH_COOKIE, fresh.refreshToken, 2_592_000)
    }

    const res = c.render(
      <Document>
        <h1>Dashboard</h1>
        <p>Logged in as: {fresh.user.email}</p>
        <p>User ID: {fresh.user.id}</p>
        <a href='/logout'>Logout</a>
      </Document>,
    )
    for (const [key, value] of responseHeaders) {
      if (key.toLowerCase() === 'set-cookie') {
        res.headers.append(key, value)
      }
    }
    return res
  })
  .get('/logout', async (c) => {
    const idpBaseUrl = process.env.IDP_BASE_URL ?? 'http://localhost:8787'
    const token = getCookie(c, FEED_SESSION_COOKIE)
    if (!Predicate.isNullish(token)) {
      // oxlint-disable-next-line rules/no-fetch -- external IdP sign-out endpoint
      await fetch(`${idpBaseUrl}/api/v1/auth/sign-out`, {
        headers: { Cookie: `${FEED_SESSION_COOKIE}=${token}` },
        method: 'POST',
      }).catch(() => null)
    }
    return redirectToLogin()
  })

export default app
