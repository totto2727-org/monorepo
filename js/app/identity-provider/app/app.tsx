import { Effect } from 'effect'
import { Hono } from 'hono'
import { remixRenderer } from 'hono-remix-middleware'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'
import { sql } from 'kysely'

import { handleAuthCallback } from '#@/feature/auth/callback.ts'
import * as DB from '#@/feature/db/kysely.ts'
import type * as Env from '#@/feature/env.ts'
import * as Greeting from '#@/feature/greeting.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'
import type { Variables } from '#@/feature/runtime/hono.ts'
import { Document } from '#@/ui/document.tsx'

// 生成済み `Cloudflare.Env` には secret (`BETTER_AUTH_SECRET` 等) が含まれず
// runtime middleware (Bindings: Env.Type) と整合しないため `Env.Type` を採用。
interface AppEnv {
  Bindings: Env.Type
  Variables: Variables
}

// middleware order は design.md L268-271 / hono-remix-cloudflare-example-structure.md §I1-6 に従い
// `logger → contextStorage → runtimeMiddleware → remixRenderer` の順。
// この順序を崩すと将来 Frame 機能を導入した際に壊れる。
//
// `Hono<AppEnv>` で generic を付けると chain 中の `app` 自己参照 (fetcher 内) が
// 型推論ループ (TS7022 / TS7023) を起こすため、route 登録に入る前に `app` を
// 一旦変数化してから chain を続ける形に分離する (saas-example でも同パターンの
// 分離はないが、generic 付き `Hono` での既知の制約)。
const app: Hono<AppEnv> = new Hono<AppEnv>()
  .use(logger())
  .use(contextStorage())
  .use(runtimeMiddleware)
  .get('/api/v1/auth/session', (c) =>
    c.var.auth.handler(
      new Request(new URL('/api/v1/auth/get-session', c.req.url), { headers: c.req.raw.headers, method: 'GET' }),
    ),
  )
  .get('/api/v1/auth/oauth/.well-known/openid-configuration', (c) =>
    c.json({
      authorization_endpoint: `${c.req.url.replace(/\/api\/v1\/auth\/oauth\/\.well-known\/openid-configuration$/, '')}/api/v1/auth/oauth2/authorize`,
      id_token_signing_alg_values_supported: ['ES256'],
      issuer: `${c.req.url.replace(/\/api\/v1\/auth\/oauth\/\.well-known\/openid-configuration$/, '')}/api/v1/auth`,
      jwks_uri: `${c.req.url.replace(/\/api\/v1\/auth\/oauth\/\.well-known\/openid-configuration$/, '')}/api/v1/auth/jwks`,
      response_types_supported: ['code'],
      scopes_supported: ['openid', 'profile', 'email'],
      subject_types_supported: ['public'],
      token_endpoint: `${c.req.url.replace(/\/api\/v1\/auth\/oauth\/\.well-known\/openid-configuration$/, '')}/api/v1/auth/oauth2/token`,
      userinfo_endpoint: `${c.req.url.replace(/\/api\/v1\/auth\/oauth\/\.well-known\/openid-configuration$/, '')}/api/v1/auth/oauth2/userinfo`,
    }),
  )
  .all('/api/v1/auth/*', (c) => c.var.auth.handler(c.req.raw))
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
        <h1>Hello, identity-provider</h1>
      </Document>,
    ),
  )
  .get('/login', (c) =>
    c.render(
      <Document title='ログイン'>
        <p>Login page (UI added in ms-02-pr4)</p>
      </Document>,
    ),
  )
  .get('/login/passkey', (c) =>
    c.render(
      <Document title='Passkey ログイン'>
        <p>Passkey login page (UI added in ms-02-pr4)</p>
      </Document>,
    ),
  )
  .get('/login/check-email', (c) => {
    const email = c.req.query('email') ?? ''
    return c.render(
      <Document title='メール確認'>
        <p>Check your email: {email}</p>
      </Document>,
    )
  })
  .get('/auth/callback', handleAuthCallback)
  .get('/register/passkey', async (c) => {
    const session = await c.var.auth.api.getSession({ headers: c.req.raw.headers })
    if (!session) {
      return c.redirect('/login')
    }
    return c.render(
      <Document title='Passkey 登録'>
        <p>Passkey registration page (UI added in ms-02-pr4)</p>
      </Document>,
    )
  })
  .get('/account', async (c) => {
    const session = await c.var.auth.api.getSession({ headers: c.req.raw.headers })
    if (!session) {
      return c.redirect('/login')
    }
    const email = session.user.email ?? ''
    const rawCreatedAt: Date | string = session.user.createdAt
    const createdAt = rawCreatedAt instanceof Date ? rawCreatedAt.toLocaleDateString('ja-JP') : rawCreatedAt
    return c.render(
      <Document title='アカウント'>
        <p>
          Account: {email} (created {createdAt})
        </p>
      </Document>,
    )
  })
  .get('/account', async (c) => {
    const session = await c.var.auth.api.getSession({ headers: c.req.raw.headers })
    if (!session) {
      return c.redirect('/login')
    }
    const email = session.user.email ?? ''
    const rawCreatedAt: Date | string = session.user.createdAt
    const createdAt = rawCreatedAt instanceof Date ? rawCreatedAt.toLocaleDateString('ja-JP') : rawCreatedAt
    return c.render(
      <Document title='アカウント'>
        <p>
          Account: {email} (created {createdAt})
        </p>
      </Document>,
    )
  })
  .get('/api/v1/hello', (c) =>
    c.var.runtime.runPromise(
      Effect.gen(function* () {
        const greeting = yield* Greeting.Service
        return c.json({ message: greeting.greet('identity-provider') })
      }),
    ),
  )
  .get('/debug/test-db', async (c) => {
    const crypto = await import('node:crypto')
    const id = crypto.randomUUID()
    const { runtime } = c.var
    try {
      const result = await runtime.runPromise(
        Effect.gen(function* () {
          const db = yield* DB.Service
          yield* Effect.promise(() =>
            db
              .insertInto('verification')
              .values({
                createdAt: sql<string>`datetime('now')`,
                expiresAt: sql<string>`datetime('now', '+1 hour')`,
                id,
                identifier: `test-debug-${id}`,
                updatedAt: sql<string>`datetime('now')`,
                value: JSON.stringify({ test: true }),
              })
              .execute(),
          )
          const found = yield* Effect.promise(() =>
            db.selectFrom('verification').selectAll().where('id', '=', id).executeTakeFirst(),
          )
          return { found, id, inserted: true }
        }),
      )
      return c.json(result)
    } catch (error: unknown) {
      return c.json({ error: String(error) })
    }
  })

export default app
