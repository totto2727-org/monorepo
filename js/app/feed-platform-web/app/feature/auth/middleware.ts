import { createBetterAuthSetupMiddleware, requireAuthMiddleware as authRequireAuthMiddleware } from 'auth'

import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as BetterAuth from './better-auth.ts'
import { setLoginReturnToCookie } from './cookie.ts'
import { preserveReturnToQueryParameterName, preserveReturnToQueryParameterValue } from './query-parameter.ts'
import { getReturnToPath } from './return-to.ts'

export const authMiddleware = createBetterAuthSetupMiddleware({
  factory,
  // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP middleware boundary executes the auth workflow once.
  runPromise: (ctx, effect) => ctx.var.runtime.runPromise(effect),
  service: BetterAuth.Service,
})

export const requireAuthMiddleware = authRequireAuthMiddleware({
  factory,
  onUnauthenticated: (ctx) => {
    setLoginReturnToCookie(getReturnToPath(ctx.req.url))
    return ctx.redirect(`/app/login?${preserveReturnToQueryParameterName}=${preserveReturnToQueryParameterValue}`)
  },
})
