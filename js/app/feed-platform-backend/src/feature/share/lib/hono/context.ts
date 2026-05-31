import type * as AuthContext from '#@/feature/auth/context.ts'
import type * as AppEnv from '#@/feature/env.ts'
import type { Variables } from '#@/feature/runtime/hono.ts'

export interface Env {
  Bindings: AppEnv.Type
  Variables: AuthContext.Variables & Variables
}
