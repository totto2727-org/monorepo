import * as BetterAuth from '#@/feature/auth/better-auth.ts'
import * as DB from '#@/feature/db/kysely.ts'
import * as Env from '#@/feature/env.ts'
import { Layer, ManagedRuntime } from 'effect'

const makeRuntime = (env: Env.Type) =>
  ManagedRuntime.make(BetterAuth.layer.pipe(Layer.provideMerge(DB.remoteLayer), Layer.provideMerge(Env.makeLayer(env))))

export type Runtime = ReturnType<typeof makeRuntime>

interface DisposableRuntimeInterface {
  readonly instance: Runtime
  [Symbol.asyncDispose](): Promise<void>
}

export class DisposableRuntime implements DisposableRuntimeInterface {
  readonly instance: Runtime

  constructor(env: Env.Type) {
    this.instance = makeRuntime(env)
  }

  async [Symbol.asyncDispose]() {
    await this.instance.dispose()
  }
}
