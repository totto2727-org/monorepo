import type { Context } from 'hono'

import type * as Env from '#@/feature/env.ts'
import type { Variables } from '#@/feature/runtime/hono.ts'

interface AuthCallbackEnv {
  readonly Bindings: Env.Type
  readonly Variables: Pick<Variables, 'auth'>
}

export const handleAuthCallback = async (c: Context<AuthCallbackEnv>) => {
  const session = await c.var.auth.api.getSession({ headers: c.req.raw.headers })
  if (!session) {
    return c.redirect('/login?error=invalid_link')
  }

  return c.redirect('/account')
}
