import { getContext as getContextFromALC } from 'hono/context-storage'

import type { Type as Bindings } from '#@/feature/env.ts'
import type { Variables } from '#@/feature/runtime/hono.ts'

export interface Env {
  Bindings: Bindings
  Variables: Variables
}

export const get = () => getContextFromALC<Env>()
