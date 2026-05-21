import { Effect } from 'effect'
import { createMiddleware } from 'hono/factory'

import * as BetterAuth from '../auth/better-auth.ts'
import type * as Env from '../env.ts'
import * as Runtime from './server.ts'

export interface Variables {
  readonly auth: BetterAuth.Instance
  readonly runtime: Runtime.Runtime
}

// TC39 `await using` によりスコープ終了時に Symbol.asyncDispose が自動実行されるため
// try/finally による明示的な `runtime.dispose()` 呼び出しは不要。
// saas-example/src/feature/runtime/hono.ts:5-11 と同形。
export const middleware = createMiddleware<{
  Bindings: Env.Type
  Variables: Variables
}>(async (c, next) => {
  await using runtime = Runtime.make(c.env)
  c.set('runtime', runtime.instance)
  const auth = await runtime.instance.runPromise(
    Effect.gen(function* () {
      return yield* BetterAuth.Service
    }),
  )
  c.set('auth', auth)
  await next()
})
