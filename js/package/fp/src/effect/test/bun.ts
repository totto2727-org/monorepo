// https://gist.github.com/dan-myles/5025ffe07df7a0b17e010573e333dda7

import type { Scope } from 'effect'

/**
 * Minimal Effect test wrapper for Bun's native test runner.
 *
 * This provides `it.effect()` and `it.scoped()` that work with `bun:test`,
 * similar to `@effect/vitest`. When the official `@effect/bun-test` package
 * is released, replace this with that package.
 *
 * @see https://github.com/Effect-TS/effect/pull/5973
 *
 * @example
 * ```ts
 * import { describe, expect, it } from "./bun-effect"
 * import { Effect, Layer } from "effect"
 *
 * describe("my test", () => {
 *   it.effect("runs an effect", () =>
 *     Effect.gen(function* () {
 *       const result = yield* someEffect
 *       expect(result).toBe(expected)
 *     }).pipe(Effect.provide(TestLayer))
 *   )
 *
 *   it.scoped("runs a scoped effect", () =>
 *     Effect.gen(function* () {
 *       const resource = yield* acquireResource
 *       expect(resource).toBeDefined()
 *     })
 *   )
 *
 *   it.effect.skip("skipped test", () => Effect.succeed(1))
 *   it.effect.only("only this test", () => Effect.succeed(1))
 * })
 * ```
 */
import { afterAll, beforeAll, describe, expect, test } from 'bun:test'
import { Effect, TestServices } from 'effect'

export { afterAll, beforeAll, describe, expect }

interface TestOptions {
  timeout?: number
}

const runTest = <E, A>(effect: Effect.Effect<A, E, TestServices.TestServices>) =>
  Effect.runPromise(effect.pipe(Effect.provide(TestServices.liveServices)))

const runTestScoped = <E, A>(effect: Effect.Effect<A, E, TestServices.TestServices | Scope.Scope>) =>
  Effect.runPromise(effect.pipe(Effect.scoped, Effect.provide(TestServices.liveServices)))

type EffectFn<A, E, R> = () => Effect.Effect<A, E, R>

export interface EffectTester {
  <A, E>(name: string, fn: EffectFn<A, E, TestServices.TestServices>, options?: number | TestOptions): void
  skip: <A, E>(name: string, fn: EffectFn<A, E, TestServices.TestServices>, options?: number | TestOptions) => void
  only: <A, E>(name: string, fn: EffectFn<A, E, TestServices.TestServices>, options?: number | TestOptions) => void
}

export interface ScopedTester {
  <A, E>(
    name: string,
    fn: EffectFn<A, E, TestServices.TestServices | Scope.Scope>,
    options?: number | TestOptions,
  ): void
  skip: <A, E>(
    name: string,
    fn: EffectFn<A, E, TestServices.TestServices | Scope.Scope>,
    options?: number | TestOptions,
  ) => void
  only: <A, E>(
    name: string,
    fn: EffectFn<A, E, TestServices.TestServices | Scope.Scope>,
    options?: number | TestOptions,
  ) => void
}

const makeEffectTest =
  (runner: typeof test) =>
  <A, E>(name: string, fn: EffectFn<A, E, TestServices.TestServices>, options?: number | TestOptions) => {
    const timeout = typeof options === 'number' ? options : options?.timeout
    runner(name, () => runTest(fn()), timeout ? { timeout } : undefined)
  }

const makeScopedTest =
  (runner: typeof test) =>
  <A, E>(name: string, fn: EffectFn<A, E, TestServices.TestServices | Scope.Scope>, options?: number | TestOptions) => {
    const timeout = typeof options === 'number' ? options : options?.timeout
    runner(name, () => runTestScoped(fn()), timeout ? { timeout } : undefined)
  }

/** Runs an Effect as a Bun test case. */
export const effect: EffectTester = Object.assign(makeEffectTest(test), {
  only: makeEffectTest(test.only),
  skip: makeEffectTest(test.skip),
})

/** Runs a scoped Effect as a Bun test case. */
export const scoped: ScopedTester = Object.assign(makeScopedTest(test), {
  only: makeScopedTest(test.only),
  skip: makeScopedTest(test.skip),
})

/** Bun test runner extended with `effect` and `scoped` helpers. */
export const it: typeof test & { effect: EffectTester; scoped: ScopedTester } = Object.assign(test, { effect, scoped })
