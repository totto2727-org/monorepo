import { Effect } from 'effect'
import { describe, expect, test } from 'vite-plus/test'

import * as Greeting from '#@/feature/greeting.ts'

describe('feed-platform-web smoke', () => {
  test('Greeting.greet returns expected string via Layer.provide + Effect.runPromise', async () => {
    const program = Effect.gen(function* () {
      const greeting = yield* Greeting.Service
      return greeting.greet('feed-platform-web')
    })
    const result = await Effect.runPromise(Effect.provide(program, Greeting.layer))
    expect(result).toBe('Hello, feed-platform-web')
  })
})
