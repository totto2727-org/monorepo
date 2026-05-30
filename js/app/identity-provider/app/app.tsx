import { Predicate } from 'effect'
import { remixRenderer } from 'hono-remix-middleware'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import { authMiddleware } from '#@/feature/auth/middleware.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'
import { factory } from '#@/feature/share/lib/hono/factory.ts'
import { AccountPage } from '#@/ui/account.tsx'
import { CheckEmailPage } from '#@/ui/check-email.tsx'
import { Document } from '#@/ui/document.tsx'
import { LoginPasskeyPage } from '#@/ui/login-passkey.tsx'
import { LoginPage } from '#@/ui/login.tsx'
import { OAuthConsentErrorPage, OAuthConsentPage } from '#@/ui/oauth-consent.tsx'
import { RegisterPasskeyPage } from '#@/ui/register-passkey.tsx'
import { isSafeReturnTo } from '#@/ui/return-to.ts'

const api = factory.createApp().all('/auth/*', (c) => c.var.auth.handler(c.req.raw))

const appRoutes = factory
  .createApp()
  .get('/', (c) =>
    c.render(
      <Document>
        <h1>Hello, identity-provider</h1>
      </Document>,
    ),
  )
  .get('/login', (c) => {
    const returnTo = c.req.query('return_to')
    const safeReturnTo = isSafeReturnTo(returnTo) ? returnTo : undefined
    return c.render(
      <Document title='ログイン'>
        <LoginPage returnTo={safeReturnTo} />
      </Document>,
    )
  })
  .get('/login/passkey', (c) => {
    const returnTo = c.req.query('return_to')
    const safeReturnTo = isSafeReturnTo(returnTo) ? returnTo : undefined
    return c.render(
      <Document title='Passkey ログイン'>
        <LoginPasskeyPage returnTo={safeReturnTo} />
      </Document>,
    )
  })
  .get('/login/check-email', (c) => {
    const email = c.req.query('email') ?? ''
    const returnTo = c.req.query('return_to')
    const safeReturnTo = isSafeReturnTo(returnTo) ? returnTo : undefined
    return c.render(
      <Document title='メール確認'>
        <CheckEmailPage email={email} returnTo={safeReturnTo} />
      </Document>,
    )
  })
  .get('/auth/magic-link/callback', async (c) => {
    const session = await c.var.auth.api.getSession({ headers: c.req.raw.headers })
    if (!session) {
      return c.redirect('/app/login?error=invalid_link')
    }
    const returnTo = c.req.query('return_to')
    return c.redirect(isSafeReturnTo(returnTo) ? returnTo : '/app/account')
  })
  .get('/auth/passkey/callback', async (c) => {
    const session = await c.var.auth.api.getSession({ headers: c.req.raw.headers })
    if (!session) {
      return c.redirect('/app/login')
    }
    const returnTo = c.req.query('return_to')
    return c.redirect(isSafeReturnTo(returnTo) ? returnTo : '/app/account')
  })
  .get('/register/passkey', async (c) => {
    const session = await c.var.auth.api.getSession({ headers: c.req.raw.headers })
    if (!session) {
      return c.redirect('/app/login')
    }
    const returnTo = c.req.query('return_to')
    const safeReturnTo = isSafeReturnTo(returnTo) ? returnTo : undefined
    return c.render(
      <Document title='Passkey 登録'>
        <RegisterPasskeyPage returnTo={safeReturnTo} />
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
        <AccountPage email={email} createdAt={createdAt} />
      </Document>,
    )
  })
  .get('/oauth/consent', async (c) => {
    const session = await c.var.auth.api.getSession({ headers: c.req.raw.headers })
    if (!session) {
      return c.redirect('/app/login')
    }
    const clientId = c.req.query('client_id')
    const redirectUri = c.req.query('redirect_uri')
    const scope = c.req.query('scope') ?? 'openid'
    const state = c.req.query('state') ?? ''
    if (Predicate.isNullish(clientId) || Predicate.isNullish(redirectUri)) {
      return c.render(
        <Document title='OAuth 認可エラー'>
          <OAuthConsentErrorPage message='client_id と redirect_uri は必須です。' />
        </Document>,
      )
    }
    return c.render(
      <Document title='OAuth 認可'>
        <OAuthConsentPage clientId={clientId} scope={scope} redirectUri={redirectUri} state={state} />
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
