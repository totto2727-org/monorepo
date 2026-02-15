import { DatabaseService } from '#@/db/service.ts'
import { Effect } from '@package/function/effect'

import { makeBetterAuth } from './better-auth.ts'

export class BetterAuthService extends Effect.Service<ReturnType<typeof makeBetterAuth>>()(
  '@app/saas-example/auth/BetterAuthService',
  {
    effect: Effect.gen(function* () {
      return makeBetterAuth(yield* DatabaseService)
    }),
  },
) {}
