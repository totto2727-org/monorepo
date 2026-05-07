import { Effect, Layer, Logger, ManagedRuntime } from 'effect'

import * as Env from '../env.ts'
import * as Greeting from '../greeting.ts'
import * as Health from '../health.ts'

// Env Service から `ENV` を取得して Logger 形式 (consoleJson / consolePretty) を選択する Layer。
// `Layer.unwrap` で `Effect<Layer<...>, ...>` を `Layer` に flatten する。
// 内部で `yield* Env.Service` するため、unwrap 後の Layer は Env を依存として要求する。
// ここでは `Layer.provide(Env.layer)` で Env 依存を閉じてしまい、Logger 専用の独立 Layer に整える。
const dynamicLoggerLayer = Layer.unwrap(
  Effect.gen(function* () {
    const env = yield* Env.Service
    return Logger.layer([env.ENV === 'production' ? Logger.consoleJson : Logger.consolePretty()])
  }),
).pipe(Layer.provide(Env.layer))

const makeRuntime = () =>
  // Env.layer (process.env.NODE_ENV 由来) を `provideMerge` で合成し、
  // Health (yield* Env) の依存を閉じる。Logger 用 Env 依存は dynamicLoggerLayer 側で
  // 既に `Layer.provide(Env.layer)` 済みのため、追加 provide は不要。
  ManagedRuntime.make(
    Health.layer.pipe(
      Layer.provideMerge(Greeting.layer),
      Layer.provideMerge(Env.layer),
      Layer.provide(dynamicLoggerLayer),
    ),
  )

export type Runtime = ReturnType<typeof makeRuntime>

// TC39 explicit resource management (`await using`) で自動破棄するための Disposable wrapper。
// saas-example/src/feature/runtime/server.ts:33-53 のパターンを踏襲。
interface DisposableRuntimeInterface {
  readonly instance: Runtime
  [Symbol.asyncDispose](): Promise<void>
}

const makeDisposableRuntime = (make: typeof makeRuntime) =>
  class DisposableRuntime implements DisposableRuntimeInterface {
    readonly instance: Runtime

    constructor() {
      this.instance = make()
    }

    async [Symbol.asyncDispose](): Promise<void> {
      await this.instance.dispose()
    }
  }

export const DisposableRuntime = makeDisposableRuntime(makeRuntime)

// 公開 entry: Hono middleware から `await using runtime = Runtime.make()` 形で利用される。
// ENV 取得は Env.layer (process.env.NODE_ENV 由来) に内部化したため引数は不要。
// saas-example が PROD/DEV/TEST 別の DisposableRuntime バリアントを返すのに対し、
// ms-01 雛形では Logger 切替を `dynamicLoggerLayer` (Env.Service 経由) に内部化したため、
// 公開 `make` は単一 Disposable バリアントを返すだけで足りる。
export const make = () => new DisposableRuntime()
