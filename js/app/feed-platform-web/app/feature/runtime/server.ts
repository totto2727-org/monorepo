import { Layer, ManagedRuntime } from 'effect'
import { dynamicLoggerLayer, Env, makeDisposableRuntime } from 'effect-hono'

import * as DB from '../db/kysely.ts'
import * as Greeting from '../greeting.ts'
import * as Health from '../health.ts'

const makeRuntime = () =>
  ManagedRuntime.make(
    Health.layer.pipe(
      Layer.provideMerge(Greeting.layer),
      Layer.provideMerge(DB.remoteLayer),
      Layer.provideMerge(dynamicLoggerLayer),
      Layer.provide(Env.layer),
    ),
  )

export type Runtime = ReturnType<typeof makeRuntime>

export const DisposableRuntime = makeDisposableRuntime(makeRuntime)

export const make = () => new DisposableRuntime()
