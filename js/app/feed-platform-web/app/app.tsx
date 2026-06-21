import { Effect, Predicate } from 'effect'
import { Hono } from 'hono'
import { remixRenderer } from 'hono-remix-middleware'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import { BackendClient } from '#@/feature/api/client.ts'
import * as BetterAuth from '#@/feature/auth/better-auth.ts'
import { authMiddleware } from '#@/feature/auth/middleware.ts'
import * as Greeting from '#@/feature/greeting.ts'
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
  .get('/login', (ctx) =>
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP auth route boundary starts the OAuth redirect once.
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const auth = yield* BetterAuth.Service
        const { headers, response } = yield* Effect.tryPromise(() =>
          auth.api.signInWithOAuth2({
            body: {
              callbackURL: '/dashboard',
              providerId: 'identity-provider',
            },
            returnHeaders: true,
          }),
        )
        return redirectWithHeaders(response.url, headers)
      }),
    ),
  )
  .get('/logout', (ctx) =>
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
        return redirectWithHeaders('/', headers)
      }),
    ),
  )
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
  .get('/api/v1/hello', (ctx) =>
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP handler boundary executes request-scoped greeting Effect.
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const greeting = yield* Greeting.Service
        return ctx.json({ message: greeting.greet('feed-platform-web') })
      }),
    ),
  )
  .get('/dashboard', (ctx) =>
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP handler boundary executes the whole dashboard dependency and render workflow once.
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const { user } = ctx.var
        if (Predicate.isNullish(user)) {
          return ctx.redirect('/login')
        }
        const client = yield* BackendClient
        const callMeResult = yield* client.callMe().pipe(Effect.orElseSucceed(() => null))
        if (!Predicate.isNullish(callMeResult)) {
          return ctx.render(
            <Document>
              <h1>Dashboard</h1>
              <p>Logged in as: {callMeResult.email}</p>
              <p>Subject: {callMeResult.sub}</p>
              <a href='/logout'>Logout</a>
            </Document>,
          )
        }
        return ctx.redirect('/login')
      }),
    ),
  )

export default app
