import { Effect } from 'effect'
import { Hono } from 'hono'
import { remixRenderer } from 'hono-remix-middleware'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import * as Greeting from '#@/feature/greeting.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'
import type { Variables } from '#@/feature/runtime/hono.ts'
import { Document } from '#@/ui/document.tsx'

// Bindings は明示しない: ENV は process.env.NODE_ENV (wrangler / vite 自動設定) を
// 単一ソースとし、Effect Service (`Env.Service`) 経由で読み取るため、
// Hono の `c.env` 経路を経由しない。Cloudflare 側 binding を後で追加する場合は
// worker-configuration.d.ts の自動生成 `Env` interface を `Bindings` に渡す形で拡張する。
interface AppEnv {
  Variables: Variables
}

// middleware order は design.md L268-271 / hono-remix-cloudflare-example-structure.md §I1-6 に従い
// `logger → contextStorage → runtimeMiddleware → remixRenderer` の順。
// この順序を崩すと将来 Frame 機能を導入した際に壊れる。
//
// `Hono<AppEnv>` で generic を付けると chain 中の `app` 自己参照 (fetcher 内) が
// 型推論ループ (TS7022 / TS7023) を起こすため、`app` の型を明示し
// fetcher の戻り値型も明示することで解消する (identity-provider 同形)。
const app: Hono<AppEnv> = new Hono<AppEnv>()
  .use(logger())
  .use(contextStorage())
  .use(runtimeMiddleware)
  .use(
    '*',
    remixRenderer({
      fetcher: (input): Promise<Response> =>
        Promise.resolve(app.fetch(input instanceof Request ? input : new Request(input))),
    }),
  )
  .get('/', (ctx) =>
    // ms-01 段階では Frame ベースのレイアウト (hono-remix-v3-cloudflare-example の
    // content-layout 系) は採用せず、素朴な c.render(<Document>...) で Hello World を出す。
    // ms-04 / ms-07 で UI を強化する際に Frame レイアウトの採用可否を再検討する。
    ctx.render(
      <Document>
        <h1>Hello, feed-platform-web</h1>
      </Document>,
    ),
  )
  .get('/api/v1/hello', (ctx) =>
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP handler boundary executes request-scoped Effect with the request runtime.
    ctx.var.runtime.runPromise(
      Effect.gen(function* () {
        const greeting = yield* Greeting.Service
        return ctx.json({ message: greeting.greet('feed-platform-web') })
      }),
    ),
  )

export default app
