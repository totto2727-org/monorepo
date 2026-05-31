import { Effect } from 'effect'
import { Hono } from 'hono'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import { authMiddleware } from '#@/feature/auth/middleware.ts'
import * as Health from '#@/feature/health.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'
import type { Env } from '#@/feature/share/lib/hono/context.ts'

// BFF entry: ms-01 段階では health entry と同形の Hello World を返すのみ。
// ms-05 (永続化) / ms-06 (入力プラグイン) で Resource-Oriented BFF (Feed BFF /
// Tag BFF / Summary BFF) の集約点として細分化される予定 (design.md S-3 参照)。
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
  .use('/api/*', authMiddleware)
  .get('/api/v1/me', (ctx) => ctx.json(ctx.var.user))

export default app
