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
