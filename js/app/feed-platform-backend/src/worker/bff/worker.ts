import { Effect } from 'effect'
import { Hono } from 'hono'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import type { AppJWTPayload } from '#@/feature/auth/jwt-payload.ts'
import { authMiddleware } from '#@/feature/auth/middleware.ts'
import * as Health from '#@/feature/health.ts'
import type { Variables } from '#@/feature/runtime/hono.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'

// Bindings は明示しない: ENV は process.env.NODE_ENV (wrangler / vite 自動設定) を
// 単一ソースとし、Effect Service (`Env.Service`) 経由で読み取るため、
// Hono の `c.env` 経路を経由しない。Cloudflare 側 binding を後で追加する場合は
// worker-configuration.d.ts の自動生成 `Env` interface を `Bindings` に渡す形で拡張する。
interface AppEnv {
  Variables: Variables & { user: AppJWTPayload }
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
  .use('/api/*', authMiddleware)
  .get('/api/v1/me', (c) => c.json(c.var.user))

export default app
