import { Predicate } from 'effect'
import { getCookie } from 'hono/cookie'
import { createMiddleware } from 'hono/factory'
import { createRemoteJWKSet, jwtVerify } from 'jose'

import { FEED_SESSION_COOKIE } from '#@/feature/auth/constants.ts'

export interface AuthUser {
  readonly id: string
  readonly email: string
}

const jwks = createRemoteJWKSet(new URL(`${process.env.IDP_BASE_URL ?? 'http://localhost:8787'}/api/v1/auth/jwks`))

export const authMiddleware = createMiddleware<{
  Variables: { user: AuthUser | null }
}>(async (c, next) => {
  const token = getCookie(c, FEED_SESSION_COOKIE)

  if (Predicate.isNullish(token)) {
    c.set('user', null)
    await next()
    return
  }

  try {
    const { payload } = await jwtVerify(token, jwks)
    const { sub } = payload
    const email = Predicate.isString(payload.email) ? payload.email : ''
    c.set('user', Predicate.isNullish(sub) ? null : { email, id: sub })
  } catch (error) {
    console.warn('[auth] JWT verification failed:', error instanceof Error ? error.message : String(error))
    c.set('user', null)
  }

  await next()
})
