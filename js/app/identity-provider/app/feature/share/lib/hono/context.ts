import type { AuthUser } from 'auth-helper'
import { getContext as getContextFromALC } from 'hono/context-storage'

import type { Type as Bindings } from '#@/feature/env.ts'
import type { Runtime } from '#@/feature/runtime/server.ts'

export interface Env {
  Bindings: Bindings
  Variables: {
    runtime: Runtime
    user: AuthUser
  }
}

export const get = () => getContextFromALC<Env>()
