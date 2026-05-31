import { Effect, Predicate, Result, String } from 'effect'

import * as Jwt from '#@/feature/auth/jwt.ts'
import { factory } from '#@/feature/share/lib/hono/factory.ts'

export const authMiddleware = factory.createMiddleware((ctx, next) =>
  // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP middleware boundary executes request-scoped auth workflow.
  ctx.var.runtime.runPromise(
    Effect.gen(function* () {
      const authorization = ctx.req.header('Authorization')
      if (Predicate.isNullish(authorization) || !authorization.startsWith('Bearer ')) {
        return ctx.json({ error: 'Unauthorized' }, 401, {
          'WWW-Authenticate': 'Bearer error="invalid_token"',
        })
      }
      const token = authorization.slice('Bearer '.length)
      if (String.isEmpty(token)) {
        return ctx.json({ error: 'Unauthorized' }, 401, {
          'WWW-Authenticate': 'Bearer error="invalid_token"',
        })
      }
      const jwt = yield* Jwt.Service
      const result = yield* Effect.result(jwt.verify(token))
      if (Result.isFailure(result)) {
        return ctx.json({ error: 'Unauthorized' }, 401, {
          'WWW-Authenticate': 'Bearer error="invalid_token"',
        })
      }
      ctx.set('user', result.success)
      return yield* Effect.promise(() => next())
    }),
  ),
)
