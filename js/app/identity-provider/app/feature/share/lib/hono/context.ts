import type { DateTime } from 'effect'
import { getContext as getContextFromALC } from 'hono/context-storage'

import type * as BetterAuth from '#@/feature/auth/better-auth.ts'
import type { Type as Bindings } from '#@/feature/env.ts'
import type { Runtime } from '#@/feature/runtime/server.ts'

export interface AuthUser {
  createdAt: DateTime.Utc
  email: string
  id: string
}

export interface Env {
  Bindings: Bindings
  Variables: {
    runtime: Runtime
    auth: BetterAuth.Instance
    user: AuthUser
  }
}

export const get = () => getContextFromALC<Env>()
