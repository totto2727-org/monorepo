import { Effect, Layer, Logger, ManagedRuntime } from 'effect'

import * as Env from '../env.ts'
import * as Greeting from '../greeting.ts'
import * as Health from '../health.ts'

// Env Service から `ENV` を取得して Logger 形式 (consoleJson / consolePretty) を選択する Layer。
// `Layer.unwrap` で `Effect<Layer<...>, ...>` を `Layer` に flatten する。
// 内部で `yield* Env.Service` するため、unwrap 後の Layer は Env を依存として要求する。
// 後段で `Layer.provideMerge(Env.makeLayer(env))` を合成すれば dependency が閉じる。
const dynamicLoggerLayer = Layer.unwrap(
  Effect.gen(function* () {
    const env = yield* Env.Service
    return Logger.layer([env.ENV === 'production' ? Logger.consoleJson : Logger.consolePretty()])
  }),
)

const makeRuntime = (env: Env.Type) => {
  // Env Layer を共有して Health (yield* Env) と dynamicLoggerLayer (yield* Env)
  // 双方の Env 依存を閉じる。`provide(dynamicLoggerLayer)` の dynamicLoggerLayer 側にも
  // Env が必要なため、unwrap 後の dynamicLoggerLayer に対して Env を `provide` してから
  // 全体に Layer.provide で重ねる。
  const envLayer = Env.makeLayer(env)
  return ManagedRuntime.make(
    Health.layer.pipe(
      Layer.provideMerge(Greeting.layer),
      Layer.provideMerge(envLayer),
      Layer.provide(dynamicLoggerLayer.pipe(Layer.provide(envLayer))),
    ),
  )
}

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

    constructor(env: Env.Type) {
      this.instance = make(env)
    }

    async [Symbol.asyncDispose](): Promise<void> {
      await this.instance.dispose()
    }
  }

export const DisposableRuntime = makeDisposableRuntime(makeRuntime)

// 公開 entry: Hono middleware から `await using runtime = Runtime.make(c.env)` 形で利用される。
// saas-example が PROD/DEV/TEST 別の DisposableRuntime バリアントを返すのに対し、
// ms-01 雛形では Logger 切替を `dynamicLoggerLayer` (Env.Service 経由) に内部化したため、
// 公開 `make` は単一 Disposable バリアントを返すだけで足りる。
export const make = (env: Env.Type) => new DisposableRuntime(env)
