import type { AppJWTPayload } from '#@/feature/auth/jwt-payload.ts'
import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as Runtime from './server.ts'

export interface Variables {
  readonly runtime: Runtime.Runtime
  readonly user: AppJWTPayload | null
}

// TC39 `await using` によりスコープ終了時に Symbol.asyncDispose が自動実行されるため
// try/finally による明示的な `runtime.dispose()` 呼び出しは不要。
// saas-example/src/feature/runtime/hono.ts:5-11 と同形。
//
// Bindings 型は明示的に指定しない: ENV は process.env.NODE_ENV (wrangler / vite 自動設定) を
// 単一ソースとし、`Env.layer` 経由で Effect Service として注入されるため、
// Hono の `c.env` を介して読み取る経路を採用していない。
// 必要が生じれば worker-configuration.d.ts (Cloudflare 自動生成) の Env interface を
// generic に渡す形で拡張する。
export const middleware = factory.createMiddleware(async (ctx, next) => {
  await using runtime = Runtime.make()
  ctx.set('runtime', runtime.instance)
  ctx.set('user', null)
  await next()
})
