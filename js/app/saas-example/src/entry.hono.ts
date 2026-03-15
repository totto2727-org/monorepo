import { Effect } from 'effect'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import * as BetterAuth from '#@/feature/auth/better-auth.ts'

import * as AuthMiddleware from './feature/auth/middleware.ts'
import type { DisposableRuntime } from './feature/di/server.ts'
import { factory } from './feature/share/lib/hono/factory.ts'

export const makeHono = (Runtime: typeof DisposableRuntime) => {
  const app = factory
    .createApp()
    .use(contextStorage())
    .use(async (c, next) => {
      await using runtime = new Runtime(c.env)
      c.set('runtime', runtime.instance)

      await next()
    })
    .use(logger())
    .get('/api/public/v1/health', () => new Response('OK'))
    .on(['POST', 'GET'], '/api/v1/auth/*', (c) =>
      Effect.gen(function* () {
        const betterAuth = yield* BetterAuth.Service
        return betterAuth.handler(c.req.raw)
      }).pipe(c.var.runtime.runPromise),
    )
    .use('/api/v1/*', AuthMiddleware.prepare)

  return app
}
