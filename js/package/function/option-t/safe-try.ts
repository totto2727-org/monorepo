/**
 * This is a port of [neverthrow](https://github.com/supermacro/neverthrow)'s `safeUnwrap` and `safeTry` to [option-t](https://github.com/gcanti/option-t).
 *
 * https://github.com/supermacro/neverthrow/blob/master/src/result.ts
 * https://github.com/supermacro/neverthrow/blob/master/src/result-async.ts
 *
 * MIT License
 *
 * Copyright (c) 2019 Giorgio Delgado
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.

 * @module
 */

import { Result as R } from '#@/option-t.ts'

/*
 * Workaround for the problem of nullable inference results due to the implementation of option-t's Result
 * Related Issue: https://github.com/option-t/option-t/issues/2362
 * Related PR: https://github.com/option-t/option-t/pull/2245
 *
 * As soon as #2245 is merged, this workaround will no longer be necessary.
 */
/**
 * Infer the Ok type from the Result type
 *
 * Verifying up to the Ok type to prevent it from becoming nullable.
 */
type InferOk<T extends R.Result<unknown, unknown>> = T extends R.Ok<infer O> ? O : never

/**
 * Infer the Err type from the Result type
 *
 * Verifying up to the Err type to prevent it from becoming nullable.
 */
type InferErr<T extends R.Result<unknown, unknown>> = T extends R.Err<infer E> ? E : never

// Original implementation
// type InferOk<T> = T extends R.Result<infer OK, unknown> ? OK : never;
// type InferErr<T> = T extends R.Result<unknown, infer ERR> ? ERR : never;

/**
 * Evaluates the given generator to a Result returned or an Err yielded from it, whichever comes first.
 *
 * This function, in combination with `safeUnwrap()`, is intended to emulate Rust's ? operator.
 * See `./main_test.ts` for examples.
 *
 * @param body - What is evaluated. In body, `yield* safeUnwrap(result)` works as Rust's `result?` expression.
 * @returns The first occurrence of either an yielded Err or a returned Result.
 */
export function safeTry<T, E>(body: () => Generator<R.Err<E>, R.Result<T, E>>): R.Result<T, E>
/**
 * Evaluates the given generator to a Result returned or an Err yielded from it, whichever comes first.
 *
 * This function, in combination with `safeUnwrap()`, is intended to emulate Rust's ? operator.
 * See `./main_test.ts` for examples.
 *
 * @param body - What is evaluated. In body, `yield* safeUnwrap(result)` works as Rust's `result?` expression.
 * @returns The first occurrence of either an yielded Err or a returned Result.
 */
export function safeTry<YieldErr extends R.Err<unknown>, GeneratorReturnResult extends R.Result<unknown, unknown>>(
  body: () => Generator<YieldErr, GeneratorReturnResult>,
): R.Result<InferOk<GeneratorReturnResult>, InferErr<YieldErr> | InferErr<GeneratorReturnResult>>
/**
 * Evaluates the given generator to a Result returned or an Err yielded from it, whichever comes first.
 *
 * This function, in combination with `safeUnwrap()`, is intended to emulate Rust's ? operator.
 * See `./main_test.ts` for examples.
 *
 * @param body - What is evaluated. In body, `yield* safeUnwrap(result)` works as Rust's `result?` expression.
 * @returns The first occurrence of either an yielded Err or a returned Result.
 */
export function safeTry<T, E>(body: () => AsyncGenerator<R.Err<E>, R.Result<T, E>>): Promise<R.Result<T, E>>
/**
 * Evaluates the given generator to a Result returned or an Err yielded from it, whichever comes first.
 *
 * This function, in combination with `safeUnwrap()`, is intended to emulate Rust's ? operator.
 * See `./main_test.ts` for examples.
 *
 * @param body - What is evaluated. In body, `yield* safeUnwrap(result)` works as Rust's `result?` expression.
 * @returns The first occurrence of either an yielded Err or a returned Result.
 */
export function safeTry<YieldErr extends R.Err<unknown>, GeneratorReturnResult extends R.Result<unknown, unknown>>(
  body: () => AsyncGenerator<YieldErr, GeneratorReturnResult>,
): Promise<R.Result<InferOk<GeneratorReturnResult>, InferErr<YieldErr> | InferErr<GeneratorReturnResult>>>

/**
 * Implementation of `safeTry`
 */
export function safeTry<T, E>(
  body: (() => Generator<R.Err<E>, R.Result<T, E>>) | (() => AsyncGenerator<R.Err<E>, R.Result<T, E>>),
): R.Result<T, E> | Promise<R.Result<T, E>> {
  const n = body().next()
  if ('then' in n) {
    return n.then((r) => r.value)
  }
  return n.value
}

/**
 * Emulates Rust's `?` operator in `safeTry`'s body. See also `safeTry`.
 *
 * Implementation of `?` operator for Ok type
 */
const _safeUnwrapOk = <const RESULT extends R.Result<unknown, unknown>>(
  result: RESULT,
): Generator<R.Err<InferErr<RESULT>>, InferOk<RESULT>> =>
  // oxlint-disable-next-line require-yield
  (function* () {
    return R.unwrapOk(result) as InferOk<RESULT>
  })()

/**
 * Emulates Rust's `?` operator in `safeTry`'s body. See also `safeTry`.
 *
 * Implementation of `?` operator for Err type
 */
const _safeUnwrapErr = <const RESULT extends R.Result<unknown, unknown>>(
  result: RESULT,
): Generator<R.Err<InferErr<RESULT>>, InferOk<RESULT>> =>
  (function* () {
    R.unwrapErr(result)
    yield result as R.Err<InferErr<RESULT>>

    throw new Error('Do not use this generator out of `safeTry`')
  })()

/**
 * Emulates Rust's `?` operator in `safeTry`'s body. See also `safeTry`.
 *
 * Implementation of `?` operator for Synchronous Result type
 *
 * @yields
 */
const _safeUnwrap = function* <const RESULT extends R.Result<unknown, unknown>>(
  result: RESULT,
): Generator<R.Err<InferErr<RESULT>>, InferOk<RESULT>> {
  if (R.isOk(result)) {
    return R.unwrapOk(result) as InferOk<RESULT>
  } else if (R.isErr(result)) {
    R.unwrapErr(result)
    yield result as R.Err<InferErr<RESULT>>

    throw new Error('Do not use this generator out of `safeTry`')
  }

  throw new TypeError('This is not Result type')
}

/**
 * Emulates Rust's `?` operator in `safeTry`'s body. See also `safeTry`.
 *
 * Implementation of `?` operator for Asynchronous Result type
 */
const _safeUnwrapAsync = <const RESULT extends R.Result<unknown, unknown>>(
  result: PromiseLike<RESULT>,
): AsyncGenerator<R.Err<InferErr<RESULT>>, InferOk<RESULT>> =>
  (async function* () {
    const r = await result

    if (R.isOk(r)) {
      return yield* _safeUnwrapOk(r as RESULT)
    } else if (R.isErr(r)) {
      return yield* _safeUnwrapErr(r as RESULT)
    }
    throw new TypeError('This is not Result type')
  })()

/**
 * Emulates Rust's `?` operator in `safeTry`'s body. See also `safeTry`.
 */
export function safeUnwrap<const RESULT extends R.Result<unknown, unknown>>(
  result: RESULT,
): Generator<R.Err<InferErr<RESULT>>, InferOk<RESULT>>

/**
 * Emulates Rust's `?` operator in `safeTry`'s body. See also `safeTry`.
 */
export function safeUnwrap<const RESULT extends R.Result<unknown, unknown>>(
  result: Promise<RESULT>,
): AsyncGenerator<R.Err<InferErr<RESULT>>, InferOk<RESULT>>

/**
 * Implementation of `safeUnwrap`
 */
export function safeUnwrap<const RESULT extends R.Result<unknown, unknown>>(
  result: RESULT | PromiseLike<RESULT>,
): Generator<R.Err<InferErr<RESULT>>, InferOk<RESULT>> | AsyncGenerator<R.Err<InferErr<RESULT>>, InferOk<RESULT>> {
  if ('then' in result) {
    return _safeUnwrapAsync(result)
  }
  return _safeUnwrap(result)
}
