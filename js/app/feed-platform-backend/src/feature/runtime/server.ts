import { Layer, ManagedRuntime } from 'effect'
import { dynamicLoggerLayer } from 'effect-hono/logger'
import { makeDisposableRuntime } from 'effect-hono/runtime'

import * as Env from '../env.ts'
import * as Greeting from '../greeting.ts'
import * as Health from '../health.ts'

const makeRuntime = () =>
  ManagedRuntime.make(
    Health.layer.pipe(
      Layer.provideMerge(Greeting.layer),
      Layer.provideMerge(dynamicLoggerLayer),
      Layer.provide(Env.layer),
    ),
  )

export type Runtime = ReturnType<typeof makeRuntime>

// TC39 explicit resource management (`await using`) で自動破棄するための Disposable wrapper。
// factory `makeDisposableRuntime` は effect-hono library から import (U-other-A 反映)。
// consumer 側は `makeRuntime` 関数定義のみを持ち、wrapper class / interface は library に委譲。
export const DisposableRuntime = makeDisposableRuntime(makeRuntime)

// 公開 entry: Hono middleware から `await using runtime = Runtime.make()` 形で利用される。
// ENV 取得は Env.layer (process.env.NODE_ENV 由来) に内部化したため引数は不要。
export const make = () => new DisposableRuntime()
