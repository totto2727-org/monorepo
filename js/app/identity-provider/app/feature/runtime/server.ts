import { Layer, ManagedRuntime } from 'effect'
import { dynamicLoggerLayer, Env as RuntimeEnv, makeDisposableRuntime } from 'effect-hono'

import * as BetterAuth from '../auth/better-auth.ts'
import * as DB from '../db/kysely.ts'
import * as EmailCloudflare from '../email/cloudflare.ts'
import * as Env from '../env.ts'
import * as Greeting from '../greeting.ts'
import * as Health from '../health.ts'

const makeRuntime = (env: Env.Type) =>
  ManagedRuntime.make(
    BetterAuth.layer.pipe(
      Layer.provideMerge(DB.remoteLayer),
      Layer.provideMerge(EmailCloudflare.layer),
      Layer.provideMerge(Greeting.layer),
      Layer.provideMerge(Health.layer),
      Layer.provideMerge(dynamicLoggerLayer),
      Layer.provideMerge(RuntimeEnv.layer),
      Layer.provide(import.meta.env.PROD ? Env.makeLayer(env) : Env.devLayer),
    ),
  )

export type Runtime = ReturnType<typeof makeRuntime>

export const DisposableRuntime = makeDisposableRuntime(makeRuntime)

export const make = (env: Env.Type) => new DisposableRuntime(env)
