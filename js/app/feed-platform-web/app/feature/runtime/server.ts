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

export const DisposableRuntime = makeDisposableRuntime(makeRuntime)

export const make = () => new DisposableRuntime()
