import { Effect, Layer } from 'effect'
import { describe, expect, test } from 'vite-plus/test'

import * as Env from '#@/feature/env.ts'
import * as Health from '#@/feature/health.ts'

describe('feed-platform-backend smoke', () => {
  test('Health.check returns ok with env injected from layer', async () => {
    const program = Effect.gen(function* () {
      const checker = yield* Health.Service
      return yield* checker.check()
    })
    const layer = Health.layer.pipe(Layer.provide(Env.makeLayer({ ENV: 'development' })))
    const result = await Effect.runPromise(Effect.provide(program, layer))
    expect(result).toEqual({ env: 'development', status: 'ok' })
  })
})
