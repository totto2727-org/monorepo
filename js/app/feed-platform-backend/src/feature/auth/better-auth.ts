import { betterAuth } from 'better-auth'
import { bearer } from 'better-auth/plugins'
import { Context, Effect, Layer } from 'effect'

import * as Env from '#@/feature/env.ts'
import * as HonoContext from '#@/feature/share/lib/hono/context.ts'

const makeInstance = (env: Env.Type) =>
  betterAuth({
    basePath: '/api/v1/auth',
    baseURL: new URL(HonoContext.get().req.url).origin,
    plugins: [bearer()],
    secret: env.BETTER_AUTH_SECRET,
    session: {
      cookieCache: {
        enabled: true,
        maxAge: 5 * 60,
        strategy: 'jwe',
      },
    },
  })

export type Instance = ReturnType<typeof makeInstance>

export const Service = Context.Service<Instance>('@app/feed-platform-backend/feature/auth/better-auth/Service')

export const layer = Layer.effect(
  Service,
  Effect.gen(function* () {
    const env = yield* Env.Service
    return makeInstance(env)
  }),
)
