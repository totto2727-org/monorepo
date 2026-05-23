import { remixRenderer } from 'hono-remix-middleware'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import { authMiddleware } from '#@/feature/auth/middleware.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'
import { factory } from '#@/feature/share/lib/hono/factory.ts'
import { Document } from '#@/ui/document.tsx'

const api = factory
  .createApp()
  .get('/auth/session', (c) =>
    c.var.auth.handler(
      new Request(new URL('/api/v1/auth/get-session', c.req.url), { headers: c.req.raw.headers, method: 'GET' }),
    ),
  )
  .get('/auth/oauth/.well-known/openid-configuration', (c) => {
    const { origin } = new URL(c.req.url)
    return c.json({
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
  .all('/auth/*', (c) => c.var.auth.handler(c.req.raw))

const appRoutes = factory
  .createApp()
  .get('/', (c) =>
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
  .get('/auth/callback', async (c) => {
    const session = await c.var.auth.api.getSession({ headers: c.req.raw.headers })
    if (!session) {
      return c.redirect('/app/login?error=invalid_link')
    }
    return c.redirect('/app/account')
  })
  .get('/register/passkey', async (c) => {
    const session = await c.var.auth.api.getSession({ headers: c.req.raw.headers })
    if (!session) {
      return c.redirect('/app/login')
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
      return c.redirect('/app/login')
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
