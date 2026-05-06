import { Effect } from 'effect'
import { Hono } from 'hono'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import type { Type as EnvType } from '#@/feature/env.ts'
import * as Health from '#@/feature/health.ts'
import type { Variables } from '#@/feature/runtime/hono.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'

interface AppEnv {
  Bindings: EnvType
  Variables: Variables
}

// BFF entry: ms-01 段階では health entry と同形の Hello World を返すのみ。
// ms-05 (永続化) / ms-06 (入力プラグイン) で Resource-Oriented BFF (Feed BFF /
// Tag BFF / Summary BFF) の集約点として細分化される予定 (design.md S-3 参照)。
const app = new Hono<AppEnv>()
  .use(contextStorage())
  .use(runtimeMiddleware)
  .use(logger())
  .get('/health', (c) =>
    c.var.runtime.runPromise(
      Effect.gen(function* () {
        const checker = yield* Health.Service
        const result = yield* checker.check()
        return c.json(result)
      }),
    ),
  )

export default app
