/**
 * Converts Effect's `Exit` to a Option-t's `Result`.
 *
 * @example
 * ```ts
 * import { fromExit } from "@totto/function/option-t/effect";
 *
 * const result = fromExit(Exit.succeed("success"));
 * // result: Result.Ok("success")
 * ```

 * @module
 */

import type { Cause } from '../effect.js'

import { Exit, Function } from '../effect.js'
import { Result } from '../option-t.js'

/**
 * Converts an Effect's `Exit` object into a Option-t's `Result` object.
 */
function fromExit_<OK, ERR_IN, ERR_OUT>(
  exit: Exit.Exit<OK, ERR_IN>,
  f: (value: Cause.Cause<ERR_IN>) => ERR_OUT,
): Result.Result<OK, ERR_OUT> {
  if (Exit.isSuccess(exit)) {
    return Result.createOk(exit.value)
  }
  return Result.createErr(f(exit.cause))
}

/**
 * Converts an Effect's `Exit` to a Option-t's `Result`, or returns a conversion function.
 */
export const fromExit: {
  <OK, ERR_IN, ERR_OUT>(
    exit: Exit.Exit<OK, ERR_IN>,
    f: (value: Cause.Cause<ERR_IN>) => ERR_OUT,
  ): Result.Result<OK, ERR_OUT>
  <ERR_IN, ERR_OUT>(
    f: (value: Cause.Cause<ERR_IN>) => ERR_OUT,
  ): <OK>(exit: Exit.Exit<OK, ERR_IN>) => Result.Result<OK, ERR_OUT>
} = Function.dual(2, fromExit_)
