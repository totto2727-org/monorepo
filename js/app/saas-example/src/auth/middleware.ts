import { Effect, Predicate } from '@package/function/effect'
import { Elysia } from 'elysia'

import { BetterAuthService } from './service.ts'

export const AuthMiddleware = Effect.gen(function* () {
  const auth = yield* BetterAuthService

  return new Elysia({ name: 'better-auth' }).mount('/auth', auth.handler).macro({
    requireAuthentication: {
      async resolve({ status, request: { headers } }) {
        const session = await auth.api.getSession({
          headers,
        })

        if (Predicate.isNullable(session)) {
          return status(401)
        }

        return {
          session: session.session,
          user: session.user,
        }
      },
    },
  })
})
