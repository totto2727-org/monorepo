import { Predicate, String } from 'effect'
import { remixRenderer } from 'hono-remix-middleware'
import { contextStorage } from 'hono/context-storage'
import { deleteCookie, getCookie } from 'hono/cookie'
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
import { getSafeReturnTo } from '#@/ui/return-to.ts'

const api = factory.createApp().all('/auth/*', (ctx) => ctx.var.auth.handler(ctx.req.raw))

const LOGIN_RETURN_TO_COOKIE = 'login_return_to'

const getStoredLoginReturnTo = (value: string | undefined): string | undefined => {
  if (Predicate.isNullish(value)) {
    return undefined
  }
  return getSafeReturnTo(decodeURIComponent(value))
}

const getLoginReturnTo = (url: string, rawReturnTo: string | undefined): string | undefined => {
  const safeReturnTo = getSafeReturnTo(rawReturnTo)
  if (Predicate.isNotNullish(safeReturnTo) && String.isNonEmpty(safeReturnTo)) {
    return safeReturnTo
  }
  const parsedUrl = new URL(url)
  if (parsedUrl.searchParams.has('client_id') && parsedUrl.searchParams.has('redirect_uri')) {
    return `/api/v1/auth/oauth2/authorize${parsedUrl.search}`
  }
  return undefined
}

const getSafeLogoutReturnTo = (value: string | undefined): string | undefined => {
  if (Predicate.isNullish(value)) {
    return undefined
  }
  try {
    const url = new URL(value)
    return url.protocol === 'http:' && url.hostname === '127.0.0.1' && url.port === '8789' ? value : undefined
  } catch {
    return getSafeReturnTo(value)
  }
}

const appRoutes = factory
  .createApp()
  .get('/', (ctx) =>
    ctx.render(
      <Document>
        <h1>Hello, identity-provider</h1>
      </Document>,
    ),
  )
  .get('/login', (ctx) => {
    const safeReturnTo = getLoginReturnTo(ctx.req.url, ctx.req.query('return_to'))
    if (Predicate.isNullish(safeReturnTo) || String.isEmpty(safeReturnTo)) {
      deleteCookie(ctx, LOGIN_RETURN_TO_COOKIE, { httpOnly: true, path: '/', sameSite: 'Lax' })
    }
    return ctx.render(
      <Document title='ログイン'>
        <LoginPage returnTo={safeReturnTo} />
      </Document>,
    )
  })
  .get('/logout', (ctx) => {
    deleteCookie(ctx, 'better-auth.session_token', { httpOnly: true, path: '/', sameSite: 'Lax' })
    const returnTo = getSafeLogoutReturnTo(ctx.req.query('return_to'))
    return ctx.redirect(returnTo ?? '/app/login')
  })
  .get('/login/passkey', (ctx) => {
    const returnTo = ctx.req.query('return_to')
    const safeReturnTo = getSafeReturnTo(returnTo)
    return ctx.render(
      <Document title='Passkey ログイン'>
        <LoginPasskeyPage returnTo={safeReturnTo} />
      </Document>,
    )
  })
  .get('/login/check-email', (ctx) => {
    const email = ctx.req.query('email') ?? ''
    const returnTo = ctx.req.query('return_to')
    const safeReturnTo = getSafeReturnTo(returnTo)
    return ctx.render(
      <Document title='メール確認'>
        <CheckEmailPage email={email} returnTo={safeReturnTo} />
      </Document>,
    )
  })
  .get('/auth/magic-link/callback', async (ctx) => {
    const session = await ctx.var.auth.api.getSession({ headers: ctx.req.raw.headers })
    if (!session) {
      return ctx.redirect('/app/login?error=invalid_link')
    }
    const returnTo =
      getSafeReturnTo(ctx.req.query('return_to')) ?? getStoredLoginReturnTo(getCookie(ctx, LOGIN_RETURN_TO_COOKIE))
    deleteCookie(ctx, LOGIN_RETURN_TO_COOKIE, { httpOnly: true, path: '/', sameSite: 'Lax' })
    return ctx.redirect(returnTo ?? '/app/account')
  })
  .get('/auth/passkey/callback', async (ctx) => {
    const session = await ctx.var.auth.api.getSession({ headers: ctx.req.raw.headers })
    if (!session) {
      return ctx.redirect('/app/login')
    }
    const returnTo =
      getSafeReturnTo(ctx.req.query('return_to')) ?? getStoredLoginReturnTo(getCookie(ctx, LOGIN_RETURN_TO_COOKIE))
    deleteCookie(ctx, LOGIN_RETURN_TO_COOKIE, { httpOnly: true, path: '/', sameSite: 'Lax' })
    return ctx.redirect(returnTo ?? '/app/account')
  })
  .get('/register/passkey', async (ctx) => {
    const session = await ctx.var.auth.api.getSession({ headers: ctx.req.raw.headers })
    if (!session) {
      return ctx.redirect('/app/login')
    }
    const returnTo = ctx.req.query('return_to')
    const safeReturnTo = getSafeReturnTo(returnTo)
    return ctx.render(
      <Document title='Passkey 登録'>
        <RegisterPasskeyPage returnTo={safeReturnTo} />
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
    const createdAt = Predicate.isString(rawCreatedAt) ? rawCreatedAt : rawCreatedAt.toLocaleDateString('ja-JP')
    return ctx.render(
      <Document title='アカウント'>
        <AccountPage email={email} createdAt={createdAt} />
      </Document>,
    )
  })
  .get('/oauth/consent', async (ctx) => {
    const session = await ctx.var.auth.api.getSession({ headers: ctx.req.raw.headers })
    if (!session) {
      return ctx.redirect('/app/login')
    }
    const clientId = ctx.req.query('client_id')
    const redirectUri = ctx.req.query('redirect_uri')
    const scope = ctx.req.query('scope') ?? 'openid'
    const state = ctx.req.query('state') ?? ''
    if (Predicate.isNullish(clientId) || Predicate.isNullish(redirectUri)) {
      return ctx.render(
        <Document title='OAuth 認可エラー'>
          <OAuthConsentErrorPage message='client_id と redirect_uri は必須です。' />
        </Document>,
      )
    }
    return ctx.render(
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
      fetcher: (input): Promise<Response> => Promise.resolve(app.fetch(new Request(input))),
    }),
  )
  .route('/app', appRoutes)

export default app
