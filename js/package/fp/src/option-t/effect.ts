/**
 * Converts Effect's `Exit` to a Option-t's `Result`.
 *
 * @example
 * ```ts
 * import { fromExit } from "@totto2727/fp/option-t/effect";
 *
 * const result = fromExit(Exit.succeed("success"));
 * // result: Result.Ok("success")
 * ```

 * @module
 */

import type { Cause } from '#@/effect.ts'

import { Exit, Function } from '#@/effect.ts'
import { Result } from '#@/option-t.ts'

/**
 * Converts an Effect's `Exit` object into a Option-t's `Result` object.
 */
const fromExit_ = <OK, ERR_IN, ERR_OUT>(
  exit: Exit.Exit<OK, ERR_IN>,
  f: (value: Cause.Cause<ERR_IN>) => ERR_OUT,
): Result.Result<OK, ERR_OUT> => (Exit.isSuccess(exit) ? Result.createOk(exit.value) : Result.createErr(f(exit.cause)))

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
