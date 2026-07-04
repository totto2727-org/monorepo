import { createBetterAuthSetupMiddleware } from 'auth-helper'
import { DateTime, Option, Predicate, Schema } from 'effect'

import { setLoginReturnToCookie } from '#@/feature/auth/cookie.ts'
import { preserveReturnToLoginPath } from '#@/feature/auth/query-parameter.ts'
import { getReturnToPath } from '#@/feature/auth/return-to.ts'
import type { AuthUser } from '#@/feature/share/lib/hono/context.ts'
import { factory } from '#@/feature/share/lib/hono/factory.ts'

import * as BetterAuth from './better-auth.ts'

const BetterAuthUserPayload = Schema.Struct({
  createdAt: Schema.Unknown,
  email: Schema.String,
  id: Schema.String,
})

const decodeBetterAuthUserPayload = Schema.decodeUnknownOption(BetterAuthUserPayload)

const mapAuthUser = (user: unknown): AuthUser | null => {
  const decodedUser = Option.getOrNull(decodeBetterAuthUserPayload(user))
  if (Predicate.isNullish(decodedUser)) {
    return null
  }
  const { createdAt: rawCreatedAt } = decodedUser
  const createdAt = (() => {
    if (Predicate.isString(rawCreatedAt)) {
      return rawCreatedAt
    }
    if (rawCreatedAt instanceof Date) {
      return rawCreatedAt.toISOString()
    }
    return null
  })()
  if (Predicate.isNullish(createdAt)) {
    return null
  }
  return {
    createdAt: DateTime.makeUnsafe(createdAt),
    email: decodedUser.email,
    id: decodedUser.id,
  }
}

export const authMiddleware = createBetterAuthSetupMiddleware({
  factory,
  mapUser: mapAuthUser,
  // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP middleware boundary executes request-scoped auth workflow.
  runPromise: (ctx, effect) => ctx.var.runtime.runPromise(effect),
  service: BetterAuth.Service,
})

export const requireAuthMiddleware = factory.createMiddleware(async (ctx, next) => {
  const { user } = ctx.var
  if (Predicate.isNullish(user)) {
    const returnTo = getReturnToPath(ctx.req.url)
    if (Predicate.isNotNullish(returnTo)) {
      setLoginReturnToCookie(returnTo)
    }
    return ctx.redirect(preserveReturnToLoginPath)
  }
  await next()
  return ctx.res
})

export const requireLoginSessionMiddleware = factory.createMiddleware(async (ctx, next) => {
  const { user } = ctx.var
  if (Predicate.isNullish(user)) {
    return ctx.redirect('/login')
  }
  await next()
  return ctx.res
})
