import type { Cause, Effect } from "@totto/function/effect"
import { schema as dataSourceTargetSchema } from "./data-source-target.js"

export type DataFetchResult = Effect.Effect<
  {
    value: string
    source: typeof dataSourceTargetSchema.Type
  },
  Cause.UnknownException
>