import type { Type as Bindings } from '#@/feature/env.ts'
import type { Runtime } from '#@/feature/runtime/server.ts'

export interface Env {
  Bindings: Bindings
  Variables: {
    runtime: Runtime
  }
}
