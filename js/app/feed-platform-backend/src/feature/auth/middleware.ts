import { createBetterAuthSetupMiddleware, requireAuthMiddleware as authRequireAuthMiddleware } from 'auth'

import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as BetterAuth from './better-auth.ts'

export const authMiddleware = createBetterAuthSetupMiddleware({
  factory,
  // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP middleware boundary executes request-scoped auth workflow.
  runPromise: (ctx, effect) => ctx.var.runtime.runPromise(effect),
  service: BetterAuth.Service,
})

export const requireAuthMiddleware = authRequireAuthMiddleware({
  factory,
  onUnauthenticated: (ctx) =>
    ctx.json({ error: 'Unauthorized' }, 401, {
      'WWW-Authenticate': 'Session error="invalid_session"',
    }),
})
