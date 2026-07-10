import { Effect, Predicate } from 'effect'
import { Hono } from 'hono'
import { remixRenderer } from 'hono-remix-middleware'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import { BackendClient } from '#@/feature/api/client.ts'
import * as BetterAuth from '#@/feature/auth/better-auth.ts'
import { deleteBetterAuthCookies, deleteLoginReturnToCookie, getLoginReturnToCookie } from '#@/feature/auth/cookie.ts'
import { authMiddleware, requireAuthMiddleware } from '#@/feature/auth/middleware.ts'
import {
  preserveReturnToQueryParameterName,
  preserveReturnToQueryParameterValue,
} from '#@/feature/auth/query-parameter.ts'
import { getReturnToPath } from '#@/feature/auth/return-to.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'
import type { Env } from '#@/feature/share/lib/hono/context.ts'
import { Document } from '#@/ui/document.tsx'

const redirectWithHeaders = (location: string, headers: Headers): Response => {
  const redirectHeaders = new Headers(headers)
  redirectHeaders.set('Location', location)
  return new Response(null, { headers: redirectHeaders, status: 302 })
}

const app: Hono<Env> = new Hono<Env>()
  .use(logger())
  .use(contextStorage())
  .use(runtimeMiddleware)
  .all('/api/v1/auth/*', (ctx) =>
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP auth route boundary delegates the request to Better Auth once.
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const auth = yield* BetterAuth.Service
        return auth.handler(ctx.req.raw)
      }),
    ),
  )
  .use('*', authMiddleware)
  .get('/api/v1/auth-callback', (ctx) => {
    const returnTo = getReturnToPath(getLoginReturnToCookie())
    deleteLoginReturnToCookie()
    return ctx.redirect(returnTo)
  })
  .get('/app/login', (ctx) =>
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP auth route boundary starts the OAuth redirect once.
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const { user } = ctx.var
        if (!Predicate.isNullish(user)) {
          return ctx.redirect('/app')
        }
        if (ctx.req.query(preserveReturnToQueryParameterName) !== preserveReturnToQueryParameterValue) {
          deleteLoginReturnToCookie()
        }
        const auth = yield* BetterAuth.Service
        const { headers, response } = yield* Effect.tryPromise(() =>
          auth.api.signInWithOAuth2({
            body: {
              callbackURL: '/api/v1/auth-callback',
              providerId: 'identity-provider',
            },
            returnHeaders: true,
          }),
        )
        return redirectWithHeaders(response.url, headers)
      }),
    ),
  )
  .post('/app/logout', (ctx) =>
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP auth route boundary clears the session and redirects once.
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const auth = yield* BetterAuth.Service
        const { headers } = yield* Effect.tryPromise(() =>
          auth.api.signOut({
            headers: ctx.req.raw.headers,
            returnHeaders: true,
          }),
        )
        deleteBetterAuthCookies(headers)
        return redirectWithHeaders('/app/login', headers)
      }),
    ),
  )
  .get('/', (ctx) => ctx.redirect('/app'))
  .use('/app/*', requireAuthMiddleware)
  .use(
    '/app/*',
    remixRenderer({
      fetcher: (input): Promise<Response> => Promise.resolve(app.fetch(new Request(input))),
    }),
  )
  .get('/app', (ctx) =>
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP handler boundary executes the whole dashboard dependency and render workflow once.
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const client = yield* BackendClient
        const user = yield* client.callMe()
        return ctx.render(
          <Document>
            <h1>Dashboard</h1>
            <p>Logged in as: {user.email}</p>
            <p>User ID: {user.id}</p>
            <form method='post' action='/app/logout'>
              <button type='submit'>Logout</button>
            </form>
          </Document>,
        )
      }),
    ),
  )

export default app
