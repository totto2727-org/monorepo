import { DateTime, Effect, Predicate } from 'effect'

import { setLoginReturnToCookie } from '#@/feature/auth/cookie.ts'
import { preserveReturnToLoginPath } from '#@/feature/auth/query-parameter.ts'
import { getReturnToPath } from '#@/feature/auth/return-to.ts'
import type { AuthUser } from '#@/feature/share/lib/hono/context.ts'
import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as BetterAuth from './better-auth.ts'

type BetterAuthSession = NonNullable<Awaited<ReturnType<BetterAuth.Instance['api']['getSession']>>>

const toAuthUser = (session: BetterAuthSession): AuthUser | null => {
  const { user } = session
  if (!Predicate.isString(user.id)) {
    return null
  }
  return {
    createdAt: DateTime.makeUnsafe(Predicate.isString(user.createdAt) ? user.createdAt : user.createdAt.toISOString()),
    email: Predicate.isString(user.email) ? user.email : '',
    id: user.id,
  }
}

const getAuthUser = async (auth: BetterAuth.Instance, headers: Headers): Promise<AuthUser | null> => {
  const session = await auth.api.getSession({ headers })
  return Predicate.isNullish(session) ? null : toAuthUser(session)
}

export const authMiddleware = factory.createMiddleware(async (ctx, next) => {
  // oxlint-disable-next-line rules/no-effect-runtime-run -- Hono middleware boundary reads request runtime service for downstream handlers.
  const auth = await ctx.var.runtime.runPromise(
    Effect.gen(function* () {
      return yield* BetterAuth.Service
    }),
  )
  ctx.set('auth', auth)
  await next()
})

export const requireAuthMiddleware = factory.createMiddleware(async (ctx, next) => {
  const user = await getAuthUser(ctx.var.auth, ctx.req.raw.headers)
  if (Predicate.isNullish(user)) {
    const returnTo = getReturnToPath(ctx.req.url)
    if (Predicate.isNotNullish(returnTo)) {
      setLoginReturnToCookie(returnTo)
    }
    return ctx.redirect(preserveReturnToLoginPath)
  }
  ctx.set('user', user)
  await next()
  return ctx.res
})

export const requireLoginSessionMiddleware = factory.createMiddleware(async (ctx, next) => {
  const user = await getAuthUser(ctx.var.auth, ctx.req.raw.headers)
  if (Predicate.isNullish(user)) {
    return ctx.redirect('/login')
  }
  ctx.set('user', user)
  await next()
  return ctx.res
})
