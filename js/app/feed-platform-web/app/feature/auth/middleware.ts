import type { AppJWTPayload } from 'auth-helper'
import { Predicate } from 'effect'
import { getCookie } from 'hono/cookie'
import { createMiddleware } from 'hono/factory'
import { createRemoteJWKSet, jwtVerify } from 'jose'

import { FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'

export interface AuthUser {
  readonly id: string
  readonly email: string
}

export const authMiddleware = createMiddleware<{
  Variables: { user: AuthUser | null }
}>(async (ctx, next) => {
  const token = getCookie(ctx, FEED_SESSION_COOKIE)

  if (Predicate.isNullish(token)) {
    ctx.set('user', null)
    await next()
    return
  }

  const idpBaseUrl = ctx.env.IDP_BASE_URL
  const jwks = createRemoteJWKSet(new URL(`${idpBaseUrl}/api/v1/auth/jwks`))

  try {
    const { payload } = await jwtVerify<AppJWTPayload>(token, jwks)
    const { sub, email } = payload
    ctx.set('user', { email, id: sub })
  } catch (error) {
    console.warn('[auth] JWT verification failed:', String(error))
    ctx.set('user', null)
  }

  await next()
})
