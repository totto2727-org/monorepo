import { getContext as getContextFromALC } from 'hono/context-storage'

import type * as BetterAuth from '#@/feature/auth/better-auth.ts'
import type { Type as Bindings } from '#@/feature/env.ts'
import type { Runtime } from '#@/feature/runtime/server.ts'

export interface Env {
  Bindings: Bindings
  Variables: {
    runtime: Runtime
    auth: BetterAuth.Instance
  }
}

export const get = () => getContextFromALC<Env>()
