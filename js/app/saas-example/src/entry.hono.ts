import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import * as AuthApp from './feature/auth/app.ts'
import * as AuthMiddleware from './feature/auth/middleware.ts'
import * as RuntimeHonoAdapter from './feature/runtime/hono.ts'
import type * as Runtime from './feature/runtime/server.ts'
import { factory } from './feature/share/lib/hono/factory.ts'

export const makeHono = (makeRuntime: typeof Runtime.make) => {
  const app = factory
    .createApp()
    .use(contextStorage())
    .use(RuntimeHonoAdapter.makeMiddleware(makeRuntime))
    .use(logger())
    .get('/api/public/v1/health', () => new Response('OK'))
    // BetterAuthインスタンスの設定と合わせること
    .route('/api/v1/auth', AuthApp.app)
    .use('/api/v1/*', AuthMiddleware.prepare)

  return app
}
