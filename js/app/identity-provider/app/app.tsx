import { Effect } from 'effect'
import { remixRenderer } from 'hono-remix-middleware'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import * as BetterAuth from '#@/feature/auth/better-auth.ts'
import { deleteLoginReturnToCookie, getLoginReturnToCookie, setLoginReturnToCookie } from '#@/feature/auth/cookie.ts'
import { authMiddleware, requireAuthMiddleware, requireLoginSessionMiddleware } from '#@/feature/auth/middleware.ts'
import {
  preserveReturnToQueryParameterName,
  preserveReturnToQueryParameterValue,
} from '#@/feature/auth/query-parameter.ts'
import { getReturnToPath } from '#@/feature/auth/return-to.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'
import { factory } from '#@/feature/share/lib/hono/factory.ts'
import { AccountPage } from '#@/ui/account.tsx'
import { CheckEmailPage } from '#@/ui/check-email.tsx'
import { Document } from '#@/ui/document.tsx'
import { LoginPasskeyPage } from '#@/ui/login-passkey.tsx'
import { LoginPage } from '#@/ui/login.tsx'
import { RegisterPasskeyPage } from '#@/ui/register-passkey.tsx'
import { SelectAccountPage } from '#@/ui/select-account.tsx'

const api = factory.createApp().all('/auth/*', (ctx) =>
  // oxlint-disable-next-line rules/no-effect-runtime-run -- Better Auth API handler is the HTTP boundary for the request runtime.
  ctx.var.runtime.runPromise(
    Effect.gen(function* () {
      const auth = yield* BetterAuth.Service
      return auth.handler(ctx.req.raw)
    }),
  ),
)

const loginRoutes = factory
  .createApp()
  .get('/', (ctx) => {
    const parsedUrl = new URL(ctx.req.url)
    if (ctx.req.query(preserveReturnToQueryParameterName) !== preserveReturnToQueryParameterValue) {
      if (parsedUrl.searchParams.has('client_id') && parsedUrl.searchParams.has('redirect_uri')) {
        setLoginReturnToCookie(`/api/v1/auth/oauth2/authorize${parsedUrl.search}`)
      } else {
        deleteLoginReturnToCookie()
      }
    }
    return ctx.render(
      <Document title='ログイン'>
        <LoginPage />
      </Document>,
    )
  })
  .get('/passkey', (ctx) =>
    ctx.render(
      <Document title='Passkey ログイン'>
        <LoginPasskeyPage />
      </Document>,
    ),
  )
  .get('/check-email', (ctx) => {
    const email = ctx.req.query('email') ?? ''
    return ctx.render(
      <Document title='メール確認'>
        <CheckEmailPage email={email} />
      </Document>,
    )
  })
  .get('/select-account', requireLoginSessionMiddleware, (ctx) => {
    const { user } = ctx.var
    const oauthQuery = new URL(ctx.req.url).searchParams.toString()
    return ctx.render(
      <Document title='アカウントの選択'>
        <SelectAccountPage email={user.email} oauthQuery={oauthQuery} />
      </Document>,
    )
  })
  .get('/callback', requireLoginSessionMiddleware, (ctx) => {
    const returnTo = getReturnToPath(getLoginReturnToCookie())
    deleteLoginReturnToCookie()
    return ctx.redirect(returnTo ?? '/app/account')
  })

const appRoutes = factory
  .createApp()
  .use(requireAuthMiddleware)
  .get('/account', (ctx) => {
    const { user } = ctx.var
    return ctx.render(
      <Document title='アカウント'>
        <AccountPage email={user.email} />
      </Document>,
    )
  })
  .get('/passkey/register', (ctx) =>
    ctx.render(
      <Document title='Passkey 登録'>
        <RegisterPasskeyPage />
      </Document>,
    ),
  )

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
  .route('/login', loginRoutes)
  .route('/app', appRoutes)

export default app
