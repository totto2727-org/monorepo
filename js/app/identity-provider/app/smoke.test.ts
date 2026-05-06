import { Effect, Layer } from 'effect'
import { describe, expect, test } from 'vite-plus/test'

import * as Env from '#@/feature/env.ts'
import * as Greeting from '#@/feature/greeting.ts'
import * as Health from '#@/feature/health.ts'

describe('identity-provider smoke', () => {
  test('Greeting.greet returns "Hello, identity-provider"', async () => {
    const program = Effect.gen(function* () {
      const greeting = yield* Greeting.Service
      return greeting.greet('identity-provider')
    })
    const result = await Effect.runPromise(Effect.provide(program, Greeting.layer))
    expect(result).toBe('Hello, identity-provider')
  })

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
