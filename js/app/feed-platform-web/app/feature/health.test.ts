import { Effect, Layer } from 'effect'
import { Env } from 'effect-hono'
import { describe, expect, test } from 'vite-plus/test'

import * as Health from './health.ts'

describe('Health', () => {
  test('check returns ok with env injected from layer', async () => {
    const program = Effect.gen(function* () {
      const checker = yield* Health.Service
      return yield* checker.check()
    })
    const layer = Health.layer.pipe(Layer.provide(Env.makeLayer('development')))
    const result = await Effect.runPromise(Effect.provide(program, layer))
    expect(result).toEqual({ env: 'development', status: 'ok' })
  })
})
