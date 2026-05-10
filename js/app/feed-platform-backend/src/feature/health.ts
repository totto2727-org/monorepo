import { Context, Effect, Layer } from 'effect'

import * as Env from './env.ts'

export interface Type {
  readonly check: () => Effect.Effect<{
    readonly status: 'ok'
    readonly env: Env.Type
  }>
}

export const Service = Context.Service<Type>('@app/feed-platform-backend/feature/health/Service')

export const layer = Layer.effect(
  Service,
  Effect.gen(function* () {
    const env = yield* Env.Service
    return {
      check: () => Effect.succeed({ env, status: 'ok' as const }),
    }
  }),
)
