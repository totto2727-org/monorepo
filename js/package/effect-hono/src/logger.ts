import { Effect, Logger } from 'effect'

import * as Env from './env.ts'

// Env Service から ENV を読み取り、production なら consoleJson、それ以外なら consolePretty を選択する Logger Layer。
// `Logger.layer` は Logger 値または `Effect<Logger, ...>` を要素に持つ ReadonlyArray を許容するため、
// 内部で `yield* Env.Service` する Effect を渡すことで Env-open な Layer を直接構成できる。
// `Layer.unwrap` も `Layer.provide(Env.layer)` も library 側では使用しない (= Env 依存 closure は consumer entry point の責務)。
export const dynamicLoggerLayer = Logger.layer([
  Effect.gen(function* () {
    const env = yield* Env.Service
    return env === 'production' ? Logger.consoleJson : Logger.consolePretty()
  }),
])
