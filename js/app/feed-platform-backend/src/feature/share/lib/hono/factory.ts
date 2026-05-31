import { createFactory } from 'hono/factory'

import type { Env } from './context.ts'

export const factory = createFactory<Env>()
