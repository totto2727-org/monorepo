/**
 * Effect type helpers and utility functions.
 *
 * @module
 */

// oxlint-disable typescript/no-explicit-any
import type { Schema, SchemaAST } from '#@/effect.ts'

import { Array, Effect, flow, Function, Option } from '#@/effect.ts'

/** Returns a constant void Effect. */
export const constVoidEffect: Function.LazyArg<Effect.Effect<void, never, never>> = Function.constant(Effect.void)

/** Wraps a function to return a void Effect, discarding its return value. */
export const asVoidEffect: <ARGS extends unknown[]>(
  fn: (...args: ARGS) => unknown,
) => (...a: ARGS) => Effect.Effect<void, never, never> = (fn) => flow(fn, constVoidEffect)

/** Extracts a synchronous decoder function type from a Schema. */
export type Create<S> =
  S extends Schema.Schema<infer A, infer I, never> ? (i: I, overrideOptions?: SchemaAST.ParseOptions) => A : never

/** Extracts the success type from an Effect-returning function. */
export type EffectFnSuccess<
  // deno-lint-ignore no-explicit-any
  FN extends (...args: any[]) => Effect.Effect<any, any, any>,
> = Effect.Effect.Success<ReturnType<FN>>

/** Extracts the error type from an Effect-returning function. */
export type EffectFnError<
  // deno-lint-ignore no-explicit-any
  FN extends (...args: any[]) => Effect.Effect<any, any, any>,
> = Effect.Effect.Error<ReturnType<FN>>

/** Extracts the context type from an Effect-returning function. */
export type EffectFnContext<
  // deno-lint-ignore no-explicit-any
  FN extends (...args: any[]) => Effect.Effect<any, any, any>,
> = Effect.Effect.Context<ReturnType<FN>>

/** A function that takes Schema-decoded args and returns an Effect. */
export type EffectFn<
  // deno-lint-ignore no-explicit-any
  ARGS extends Schema.Schema<any, any, never>,
  // deno-lint-ignore no-explicit-any
  RETURNED extends Effect.Effect<any, any, any>,
> = (args: ARGS['Type']) => RETURNED

/** Returns `Option.some` wrapping a non-empty array, or `Option.none` if empty. */
export const nonEmptyArrayOrNone = <const T>(args: T[]): Option.Option<Array.NonEmptyArray<T>> =>
  Array.isNonEmptyArray(args) ? Option.some(args) : Option.none()

/** Applies a side-effect function to each element of an array, then returns the array unchanged. */
export const tap =
  <const T extends ReadonlyArray<unknown>>(fn: (v: Array.ReadonlyArray.Infer<T>) => void): ((vs: T) => T) =>
  (vs) => {
    for (const v of vs) {
      fn(v as Array.ReadonlyArray.Infer<T>)
    }
    return vs
  }
