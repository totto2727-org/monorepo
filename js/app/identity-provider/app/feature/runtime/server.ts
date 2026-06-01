import { Layer, ManagedRuntime } from 'effect'
import { dynamicLoggerLayer, Env as RuntimeEnv, makeDisposableRuntime } from 'effect-hono'

import * as BetterAuth from '../auth/better-auth.ts'
import * as DB from '../db/kysely.ts'
import * as EmailCloudflare from '../email/cloudflare.ts'
import * as EmailMock from '../email/mock.ts'
import * as Env from '../env.ts'

const makeProdRuntime = () =>
  ManagedRuntime.make(
    BetterAuth.layer.pipe(
      Layer.provideMerge(DB.remoteLayer),
      Layer.provideMerge(EmailCloudflare.layer),
      Layer.provideMerge(dynamicLoggerLayer),
      Layer.provideMerge(RuntimeEnv.layer),
      Layer.provideMerge(Env.prodLayer),
    ),
  )

const makeDevRuntime = () =>
  ManagedRuntime.make(
    BetterAuth.layer.pipe(
      Layer.provideMerge(DB.remoteLayer),
      Layer.provideMerge(EmailMock.layer),
      Layer.provideMerge(dynamicLoggerLayer),
      Layer.provideMerge(RuntimeEnv.layer),
      Layer.provideMerge(Env.devLayer),
    ),
  )

export type Runtime = ReturnType<typeof makeProdRuntime>

export const DisposableProdRuntime = makeDisposableRuntime(makeProdRuntime)
export const DisposableDevRuntime = makeDisposableRuntime(makeDevRuntime)

export const makeProd = () => new DisposableProdRuntime()
export const makeDev = () => new DisposableDevRuntime()

export const make = () => (import.meta.env.PROD ? makeProd() : makeDev())
