import type { Option } from 'effect'
import { getContext as getContextFromALC } from 'hono/context-storage'

import type * as BetterAuth from '#@/feature/auth/better-auth.ts'
import type { Runtime } from '#@/feature/di/server.ts'
import type { Type as Bindings } from '#@/feature/env.ts'

export interface Env {
  Bindings: Bindings
  Variables: {
    runtime: Runtime
    auth: Option.Option<{
      user: BetterAuth.Instance['$Infer']['Session']['user']
      session: BetterAuth.Instance['$Infer']['Session']['session']
    }>
  }
}

export const get = () => getContextFromALC<Env>()
