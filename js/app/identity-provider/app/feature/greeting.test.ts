import { Effect } from 'effect'
import { describe, expect, test } from 'vite-plus/test'

import * as Greeting from './greeting.ts'

describe('Greeting', () => {
  test('greet returns "Hello, identity-provider"', async () => {
    const program = Effect.gen(function* () {
      const greeting = yield* Greeting.Service
      return greeting.greet('identity-provider')
    })
    const result = await Effect.runPromise(Effect.provide(program, Greeting.layer))
    expect(result).toBe('Hello, identity-provider')
  })
})
