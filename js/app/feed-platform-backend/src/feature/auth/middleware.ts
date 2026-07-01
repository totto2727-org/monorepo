import { createRequiredBetterAuthMiddleware } from 'auth-helper'

import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as BetterAuth from './better-auth.ts'

export const authMiddleware = createRequiredBetterAuthMiddleware({
  factory,
  // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP middleware boundary executes request-scoped auth workflow.
  runPromise: (ctx, runtime) => ctx.var.runtime.runPromise(runtime),
  service: BetterAuth.Service,
})
