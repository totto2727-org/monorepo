import { Exit } from '../effect.js'
/**
 * Converts Option-t's `Result` to Effect's `Exit`.
 *
 * @example
 * ```ts
 * import { fromResult } from "@totto/function/effect/option-t";
 *
 * const exit = fromResult(Result.createOk("success"));
 * // exit: Exit.Success("success")
 * ```
 *
 * @module
 */
import { Result } from '../option-t.js'

/**
 * Converts an Option-t's `Result` object into an Effect's `Exit` object.
 */
export function fromResult<OK, ERR>(result: Result.Result<OK, ERR>): Exit.Exit<OK, ERR> {
  if (Result.isOk(result)) {
    return Exit.succeed(Result.unwrapOk(result))
  }
  return Exit.fail(Result.unwrapErr(result))
}
