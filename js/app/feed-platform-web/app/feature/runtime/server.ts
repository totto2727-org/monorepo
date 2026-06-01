import { Layer, ManagedRuntime } from 'effect'
import { dynamicLoggerLayer, Env as RuntimeEnv, makeDisposableRuntime } from 'effect-hono'
import { FetchHttpClient } from 'effect/unstable/http'

import * as Api from '../api/client.ts'
import * as DB from '../db/kysely.ts'
import * as AppEnv from '../env.ts'
import * as Greeting from '../greeting.ts'
import * as Health from '../health.ts'

const makeProdRuntime = () =>
  ManagedRuntime.make(
    Health.layer.pipe(
      Layer.provideMerge(Greeting.layer),
      Layer.provideMerge(Api.liveLayer),
      Layer.provideMerge(DB.remoteLayer),
      Layer.provideMerge(FetchHttpClient.layer),
      Layer.provideMerge(dynamicLoggerLayer),
      Layer.provideMerge(RuntimeEnv.layer),
      Layer.provideMerge(AppEnv.prodLayer),
    ),
  )

const makeDevRuntime = () =>
  ManagedRuntime.make(
    Health.layer.pipe(
      Layer.provideMerge(Greeting.layer),
      Layer.provideMerge(Api.liveLayer),
      Layer.provideMerge(DB.remoteLayer),
      Layer.provideMerge(FetchHttpClient.layer),
      Layer.provideMerge(dynamicLoggerLayer),
      Layer.provideMerge(RuntimeEnv.layer),
      Layer.provideMerge(AppEnv.devLayer),
    ),
  )

export type Runtime = ReturnType<typeof makeProdRuntime>

export const DisposableProdRuntime = makeDisposableRuntime(makeProdRuntime)
export const DisposableDevRuntime = makeDisposableRuntime(makeDevRuntime)

export const makeProd = () => new DisposableProdRuntime()
export const makeDev = () => new DisposableDevRuntime()

export const make = () => (import.meta.env.PROD ? makeProd() : makeDev())
