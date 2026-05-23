import { Effect, Predicate } from 'effect'
import { Hono } from 'hono'
import { remixRenderer } from 'hono-remix-middleware'
import { contextStorage } from 'hono/context-storage'
import { getCookie } from 'hono/cookie'
import { logger } from 'hono/logger'

import { BackendClient, liveLayer } from '#@/feature/api/client.ts'
import { handleAuthCallback } from '#@/feature/auth/callback.ts'
import { FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'
import { authMiddleware } from '#@/feature/auth/middleware.ts'
import type { AuthUser } from '#@/feature/auth/middleware.ts'
import { buildAuthorizeUrl, generateChallenge, generateState, generateVerifier } from '#@/feature/auth/oauth-client.ts'
import * as Greeting from '#@/feature/greeting.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'
import type { Variables } from '#@/feature/runtime/hono.ts'
import { Document } from '#@/ui/document.tsx'

// Bindings は明示しない: ENV は process.env.NODE_ENV (wrangler / vite 自動設定) を
// 単一ソースとし、Effect Service (`Env.Service`) 経由で読み取るため、
// Hono の `c.env` 経路を経由しない。Cloudflare 側 binding を後で追加する場合は
// worker-configuration.d.ts の自動生成 `Env` interface を `Bindings` に渡す形で拡張する。
interface AppEnv {
  Variables: Variables & { user: AuthUser | null }
}

// middleware order は design.md L268-271 / hono-remix-cloudflare-example-structure.md §I1-6 に従い
// `logger → contextStorage → runtimeMiddleware → remixRenderer` の順。
// この順序を崩すと将来 Frame 機能を導入した際に壊れる。
//
// `Hono<AppEnv>` で generic を付けると chain 中の `app` 自己参照 (fetcher 内) が
// 型推論ループ (TS7022 / TS7023) を起こすため、`app` の型を明示し
// fetcher の戻り値型も明示することで解消する (identity-provider 同形)。
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
    // ms-01 段階では Frame ベースのレイアウト (hono-remix-v3-cloudflare-example の
    // content-layout 系) は採用せず、素朴な c.render(<Document>...) で Hello World を出す。
    // ms-04 / ms-07 で UI を強化する際に Frame レイアウトの採用可否を再検討する。
    c.render(
      <Document>
        <h1>Hello, feed-platform-web</h1>
      </Document>,
    ),
  )
  .get('/login', async () => {
    const idpBaseUrl = process.env.IDP_BASE_URL ?? 'http://localhost:8787'
    const clientId = process.env.OAUTH_CLIENT_ID ?? 'feed-platform-web'
    const webBaseUrl = process.env.WEB_BASE_URL ?? 'http://localhost:8788'

    const verifier = generateVerifier()
    const state = generateState()
    const codeChallenge = await generateChallenge(verifier)

    const redirectUri = `${webBaseUrl}/auth/callback`
    const authorizeUrl = buildAuthorizeUrl({
      clientId,
      codeChallenge,
      idpBaseUrl,
      redirectUri,
      state,
    })

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
    const { email, id } = await Effect.runPromise(
      Effect.provide(
        Effect.gen(function* () {
          const client = yield* BackendClient
          return yield* client.callMe(c.req.header('Cookie'))
        }),
        liveLayer,
      ),
    )
    return c.render(
      <Document>
        <h1>Dashboard</h1>
        <p>Logged in as: {email}</p>
        <p>User ID: {id}</p>
        <a href='/logout'>Logout</a>
      </Document>,
    )
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
    const headers = new Headers({ Location: '/login' })
    headers.append('Set-Cookie', `${FEED_SESSION_COOKIE}=; Max-Age=0; Path=/; SameSite=Lax; HttpOnly`)
    return new Response(null, { headers, status: 302 })
  })

export default app
