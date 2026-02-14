import { Exit } from '#@/effect.ts'
/**
 * Converts Option-t's `Result` to Effect's `Exit`.
 *
 * @example
 * ```ts
 * import { fromResult } from "@package/function/effect/option-t";
 *
 * const exit = fromResult(Result.createOk("success"));
 * // exit: Exit.Success("success")
 * ```
 *
 * @module
 */
import { Result } from '#@/option-t.ts'

/**
 * Converts an Option-t's `Result` object into an Effect's `Exit` object.
 */
export const fromResult = <OK, ERR>(result: Result.Result<OK, ERR>): Exit.Exit<OK, ERR> =>
  Result.isOk(result) ? Exit.succeed(Result.unwrapOk(result)) : Exit.fail(Result.unwrapErr(result))
