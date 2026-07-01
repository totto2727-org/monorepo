import { Effect } from 'effect'
import { Hono } from 'hono'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import * as Health from '#@/feature/health.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'
import type { Env } from '#@/feature/share/lib/hono/context.ts'

const app = new Hono<Env>()
  .use(contextStorage())
  .use(runtimeMiddleware)
  .use(logger())
  .get('/health', (ctx) =>
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP handler boundary executes request-scoped Effect with the request runtime.
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const checker = yield* Health.Service
        const result = yield* checker.check()
        return ctx.json(result)
      }),
    ),
  )

export default app
