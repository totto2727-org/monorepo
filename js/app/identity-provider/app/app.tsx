import { remixRenderer } from 'hono-remix-middleware'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import { authMiddleware } from '#@/feature/auth/middleware.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'
import { factory } from '#@/feature/share/lib/hono/factory.ts'
import { Document } from '#@/ui/document.tsx'

const api = factory
  .createApp()
  .get('/auth/session', (ctx) =>
    ctx.var.auth.handler(
      new Request(new URL('/api/v1/auth/get-session', ctx.req.url), { headers: ctx.req.raw.headers, method: 'GET' }),
    ),
  )
  .get('/auth/oauth/.well-known/openid-configuration', (ctx) => {
    const { origin } = new URL(ctx.req.url)
    return ctx.json({
      authorization_endpoint: `${origin}/api/v1/auth/oauth2/authorize`,
      id_token_signing_alg_values_supported: ['ES256'],
      issuer: `${origin}/api/v1/auth`,
      jwks_uri: `${origin}/api/v1/auth/jwks`,
      response_types_supported: ['code'],
      scopes_supported: ['openid', 'profile', 'email'],
      subject_types_supported: ['public'],
      token_endpoint: `${origin}/api/v1/auth/oauth2/token`,
      userinfo_endpoint: `${origin}/api/v1/auth/oauth2/userinfo`,
    })
  })
  .all('/auth/*', (ctx) => ctx.var.auth.handler(ctx.req.raw))

const appRoutes = factory
  .createApp()
  .get('/', (ctx) =>
    ctx.render(
      <Document>
        <h1>Hello, identity-provider</h1>
      </Document>,
    ),
  )
  .get('/login', (ctx) =>
    ctx.render(
      <Document title='ログイン'>
        <p>Login page (UI added in ms-02-pr4)</p>
      </Document>,
    ),
  )
  .get('/login/passkey', (ctx) =>
    ctx.render(
      <Document title='Passkey ログイン'>
        <p>Passkey login page (UI added in ms-02-pr4)</p>
      </Document>,
    ),
  )
  .get('/login/check-email', (ctx) => {
    const email = ctx.req.query('email') ?? ''
    return ctx.render(
      <Document title='メール確認'>
        <p>Check your email: {email}</p>
      </Document>,
    )
  })
  .get('/auth/callback', async (ctx) => {
    const session = await ctx.var.auth.api.getSession({ headers: ctx.req.raw.headers })
    if (!session) {
      return ctx.redirect('/app/login?error=invalid_link')
    }
    return ctx.redirect('/app/account')
  })
  .get('/register/passkey', async (ctx) => {
    const session = await ctx.var.auth.api.getSession({ headers: ctx.req.raw.headers })
    if (!session) {
      return ctx.redirect('/app/login')
    }
    return ctx.render(
      <Document title='Passkey 登録'>
        <p>Passkey registration page (UI added in ms-02-pr4)</p>
      </Document>,
    )
  })
  .get('/account', async (ctx) => {
    const session = await ctx.var.auth.api.getSession({ headers: ctx.req.raw.headers })
    if (!session) {
      return ctx.redirect('/app/login')
    }
    const email = session.user.email ?? ''
    const rawCreatedAt: Date | string = session.user.createdAt
    const createdAt = rawCreatedAt instanceof Date ? rawCreatedAt.toLocaleDateString('ja-JP') : rawCreatedAt
    return ctx.render(
      <Document title='アカウント'>
        <p>
          Account: {email} (created {createdAt})
        </p>
      </Document>,
    )
  })

const app = factory
  .createApp()
  .use(logger())
  .use(contextStorage())
  .use(runtimeMiddleware)
  .use(authMiddleware)
  .route('/api/v1', api)
  .use(
    '*',
    remixRenderer({
      fetcher: (input): Promise<Response> =>
        Promise.resolve(app.fetch(input instanceof Request ? input : new Request(input))),
    }),
  )
  .route('/app', appRoutes)

export default app
