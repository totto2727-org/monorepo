/**
 * Effect type helpers and utility functions.
 *
 * @module
 */

// oxlint-disable typescript/no-explicit-any

import { Array, Effect, flow, Function, Option } from '#@/effect.ts'

/** Returns a constant void Effect. */
export const constVoidEffect: Function.LazyArg<Effect.Effect<void>> = Function.constant(Effect.void)

/** Wraps a function to return a void Effect, discarding its return value. */
export const asVoidEffect: <ARGS extends unknown[]>(
  fn: (...args: ARGS) => unknown,
) => (...a: ARGS) => Effect.Effect<void> = (fn) => flow(fn, constVoidEffect)

/** Extracts the success type from an Effect-returning function. */
export type EffectFnSuccess<
  // deno-lint-ignore no-explicit-any
  FN extends (...args: any[]) => Effect.Effect<any, any, any>,
> = Effect.Success<ReturnType<FN>>

/** Extracts the error type from an Effect-returning function. */
export type EffectFnError<
  // deno-lint-ignore no-explicit-any
  FN extends (...args: any[]) => Effect.Effect<any, any, any>,
> = Effect.Error<ReturnType<FN>>

/** Extracts the services type from an Effect-returning function. */
export type EffectFnServices<
  // deno-lint-ignore no-explicit-any
  FN extends (...args: any[]) => Effect.Effect<any, any, any>,
> = Effect.Services<ReturnType<FN>>

/** Returns `Option.some` wrapping a non-empty array, or `Option.none` if empty. */
export const nonEmptyArrayOrNone = <const T>(args: T[]): Option.Option<Array.NonEmptyArray<T>> =>
  Array.isArrayNonEmpty(args) ? Option.some(args) : Option.none()

/** Applies a side-effect function to each element of an array, then returns the array unchanged. */
export const tap =
  <const T extends readonly unknown[]>(fn: (v: Array.ReadonlyArray.Infer<T>) => void): ((vs: T) => T) =>
  (vs) => {
    for (const v of vs) {
      // oxlint-disable-next-line typescript/no-unsafe-type-assertion
      fn(v as Array.ReadonlyArray.Infer<T>)
    }
    return vs
  }
