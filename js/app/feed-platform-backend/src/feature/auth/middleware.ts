import type { AppJWTPayload } from 'auth-helper'
import { Effect, Exit, Predicate, String } from 'effect'
import { createMiddleware } from 'hono/factory'

import { JwtService, liveLayer } from '#@/feature/auth/jwt.ts'

export const authMiddleware = createMiddleware<{
  Variables: { user: AppJWTPayload }
}>(async (c, next) => {
  const authorization = c.req.header('Authorization')
  if (Predicate.isNullish(authorization) || !authorization.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized' }, 401, {
      'WWW-Authenticate': 'Bearer error="invalid_token"',
    })
  }
  const token = authorization.slice('Bearer '.length)
  if (String.isEmpty(token)) {
    return c.json({ error: 'Unauthorized' }, 401, {
      'WWW-Authenticate': 'Bearer error="invalid_token"',
    })
  }
  const exit = await Effect.runPromiseExit(
    Effect.provide(
      Effect.gen(function* () {
        const jwt = yield* JwtService
        return yield* jwt.verify(token)
      }),
      liveLayer,
    ),
  )
  if (!Exit.isSuccess(exit)) {
    return c.json({ error: 'Unauthorized' }, 401, {
      'WWW-Authenticate': 'Bearer error="invalid_token"',
    })
  }
  c.set('user', exit.value)
  return next()
})
