import type { User } from 'auth'
import { getContext as getContextFromALC } from 'hono/context-storage'

import type { Type as Bindings } from '#@/feature/env.ts'
import type { Runtime } from '#@/feature/runtime/server.ts'

export interface Env {
  Bindings: Bindings
  Variables: {
    runtime: Runtime
    user: User
  }
}

export const get = () => getContextFromALC<Env>()
