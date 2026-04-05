import { Layer, Logger, ManagedRuntime } from 'effect'

import * as BetterAuth from '#@/feature/auth/better-auth.ts'
import * as DB from '#@/feature/db/kysely.ts'
import * as Env from '#@/feature/env.ts'

const makeRuntime = (env: Env.Type) =>
  ManagedRuntime.make(
    //
    BetterAuth.layer.pipe(
      //
      Layer.provideMerge(DB.remoteLayer),
      Layer.provideMerge(Env.makeLayer(env)),
      Layer.provide(Logger.layer([Logger.consoleJson])),
    ),
  )

const makeDevRuntime = (env: Env.Type) =>
  ManagedRuntime.make(
    //
    BetterAuth.layer.pipe(
      //
      Layer.provideMerge(DB.remoteLayer),
      Layer.provideMerge(Env.makeLayer(env)),
      Layer.provide(Logger.layer([Logger.consolePretty()])),
    ),
  )

const makeTestRuntime = makeDevRuntime

export type Runtime = ReturnType<typeof makeRuntime>

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
export const DisposableDevRuntime = makeDisposableRuntime(makeDevRuntime)
export const DisposableTestRuntime = makeDisposableRuntime(makeTestRuntime)

export const make = (env: Env.Type) =>
  import.meta.env.PROD ? new DisposableRuntime(env) : new DisposableDevRuntime(env)

export const makeTest = (env: Env.Type) => new DisposableTestRuntime(env)
