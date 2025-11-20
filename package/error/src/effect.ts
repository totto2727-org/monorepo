import { type Cause, Data } from "@totto/function/effect"
import type * as Error from "./error.js"

export type ErrorClassType<
  TAG extends string,
  PROPERTIES extends Readonly<Record<string, unknown>>,
> = new (
  args: PROPERTIES,
) => Cause.YieldableError & {
  readonly _tag: TAG
} & PROPERTIES

type RFC7807ErrorClassType = ErrorClassType<
  "@package/error/effect/RFC7807Error",
  { readonly cause: Error.RFC7807Error }
>
const RFC7807ErrorClass: RFC7807ErrorClassType = Data.TaggedError(
  "@package/error/effect/RFC7807Error",
)
export class RFC7807Error extends RFC7807ErrorClass {
  constructor(error: Error.RFC7807Error) {
    super({ cause: error })
  }
}

type HTTPErrorClassType<T extends number> = ErrorClassType<
  "@package/error/effect/HTTPError",
  { readonly cause: Error.HTTPError<T> }
>
const HTTPErrorClass: HTTPErrorClassType<number> = Data.TaggedError(
  "@package/error/effect/HTTPError",
)
export class HTTPError<const T extends number> extends HTTPErrorClass {
  override cause: Error.HTTPError<T>

  constructor(cause: Error.HTTPError<T>) {
    super({ cause })
    this.cause = cause
  }
}
