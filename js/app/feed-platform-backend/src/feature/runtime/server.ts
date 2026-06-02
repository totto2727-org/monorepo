import { Layer, ManagedRuntime } from 'effect'
import { dynamicLoggerLayer, Env as RuntimeEnv, makeDisposableRuntime } from 'effect-hono'

import * as Jwt from '../auth/jwt.ts'
import * as AppEnv from '../env.ts'
import * as Greeting from '../greeting.ts'
import * as Health from '../health.ts'

const makeRuntime = (env: AppEnv.Type) =>
  ManagedRuntime.make(
    Health.layer.pipe(
      Layer.provideMerge(Greeting.layer),
      Layer.provideMerge(Jwt.layer),
      Layer.provideMerge(dynamicLoggerLayer),
      Layer.provideMerge(RuntimeEnv.layer),
      Layer.provideMerge(AppEnv.makeLayer(env)),
    ),
  )

export type Runtime = ReturnType<typeof makeRuntime>

// TC39 explicit resource management (`await using`) で自動破棄するための Disposable wrapper。
// factory `makeDisposableRuntime` は effect-hono library から import (U-other-A 反映)。
// consumer 側は `makeRuntime` 関数定義のみを持ち、wrapper class / interface は library に委譲。
export const DisposableRuntime = makeDisposableRuntime(makeRuntime)

// 公開 entry: Hono middleware から `await using runtime = Runtime.make(ctx.env)` 形で利用される。
export const make = (env: AppEnv.Type) => new DisposableRuntime(env)
