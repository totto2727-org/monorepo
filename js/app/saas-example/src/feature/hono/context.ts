import { getContext as getContextFromALC } from 'hono/context-storage'

import type { Runtime } from '#@/feature/di/server.ts'
import type { Type as Bindings } from '#@/feature/env.ts'

export interface Env {
  Bindings: Bindings
  Variables: {
    runtime: Runtime
  }
}

export const getContext = () => getContextFromALC<Env>()
