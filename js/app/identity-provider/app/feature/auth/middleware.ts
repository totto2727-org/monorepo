import {
  createBetterAuthSetupMiddleware,
  requireAuthMiddleware as authHelperRequireAuthMiddleware,
  toIdentityProviderAuthUser,
} from 'auth-helper'
import { Predicate } from 'effect'

import { setLoginReturnToCookie } from '#@/feature/auth/cookie.ts'
import { preserveReturnToLoginPath } from '#@/feature/auth/query-parameter.ts'
import { getReturnToPath } from '#@/feature/auth/return-to.ts'
import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as BetterAuth from './better-auth.ts'

export const authMiddleware = createBetterAuthSetupMiddleware({
  factory,
  mapUser: toIdentityProviderAuthUser,
  onAuth: (ctx, auth) => {
    ctx.set('auth', auth)
  },
  // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP middleware boundary executes request-scoped auth workflow.
  runPromise: (ctx, effect) => ctx.var.runtime.runPromise(effect),
  service: BetterAuth.Service,
})

export const requireAuthMiddleware = authHelperRequireAuthMiddleware({
  factory,
  onUnauthenticated: (ctx) => {
    const returnTo = getReturnToPath(ctx.req.url)
    if (Predicate.isNotNullish(returnTo)) {
      setLoginReturnToCookie(returnTo)
    }
    return ctx.redirect(preserveReturnToLoginPath)
  },
})

export const requireLoginSessionMiddleware = authHelperRequireAuthMiddleware({
  factory,
  onUnauthenticated: (ctx) => ctx.redirect('/login'),
})
