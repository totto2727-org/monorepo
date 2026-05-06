import { Effect } from 'effect'
import { Hono } from 'hono'
import { remixRenderer } from 'hono-remix-middleware'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import type { Type as EnvType } from '#@/feature/env.ts'
import * as Greeting from '#@/feature/greeting.ts'
import { middleware as runtimeMiddleware } from '#@/feature/runtime/hono.ts'
import type { Variables } from '#@/feature/runtime/hono.ts'
import { Document } from '#@/ui/document.tsx'

interface AppEnv {
  Bindings: EnvType
  Variables: Variables
}

// middleware order は design.md L268-271 / hono-remix-cloudflare-example-structure.md §I1-6 に従い
// `logger → contextStorage → runtimeMiddleware → remixRenderer` の順。
// この順序を崩すと将来 Frame 機能を導入した際に壊れる。
//
// `Hono<AppEnv>` で generic を付けると chain 中の `app` 自己参照 (fetcher 内) が
// 型推論ループ (TS7022 / TS7023) を起こすため、route 登録に入る前に `app` を
// 一旦変数化してから chain を続ける形に分離する (saas-example でも同パターンの
// 分離はないが、generic 付き `Hono` での既知の制約)。
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
  .get('/', (c) =>
    // ms-01 段階では PageOrFrame は採用せず、素朴な c.render(<Document>...) で Hello World を出す
    // (TC-022 観測対象)。ms-04 / ms-07 で UI を強化する際に PageOrFrame の採用可否を再検討する。
    c.render(
      <Document>
        <h1>Hello, identity-provider</h1>
      </Document>,
    ),
  )
  .get('/api/v1/hello', (c) =>
    c.var.runtime.runPromise(
      Effect.gen(function* () {
        const greeting = yield* Greeting.Service
        return c.json({ message: greeting.greet('identity-provider') })
      }),
    ),
  )

export default app
