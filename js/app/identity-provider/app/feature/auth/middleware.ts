import { createBetterAuthSetupMiddleware, requireAuthMiddleware as authRequireAuthMiddleware } from 'auth'
import { Predicate } from 'effect'

import { setLoginReturnToCookie } from '#@/feature/auth/cookie.ts'
import { preserveReturnToLoginPath } from '#@/feature/auth/query-parameter.ts'
import { getReturnToPath } from '#@/feature/auth/return-to.ts'
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
  onUnauthenticated: (ctx) => {
    const returnTo = getReturnToPath(ctx.req.url)
    if (Predicate.isNotNullish(returnTo)) {
      setLoginReturnToCookie(returnTo)
    }
    return ctx.redirect(preserveReturnToLoginPath)
  },
})

export const requireLoginSessionMiddleware = authRequireAuthMiddleware({
  factory,
  onUnauthenticated: (ctx) => ctx.redirect('/login'),
})
