import type { Cause, Effect } from "@totto/function/effect"
import type * as DataSourceTarget from "./data-source-target.js"

export type DataFetchResult = Effect.Effect<
  {
    value: string
    source: typeof DataSourceTarget.schema.Type
  },
  Cause.UnknownException
>
