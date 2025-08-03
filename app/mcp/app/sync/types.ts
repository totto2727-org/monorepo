import type { Cause, Effect } from "@totto/function/effect"
import type { TargetDocument } from "#@/mcp/types.js"

export type DataSourceType = "text" | "firecrawl"

export type DataSourceTarget = {
  type: DataSourceType
  url: URL
}

export type DataSourceConfig = {
  target: TargetDocument
  dataSources: DataSourceTarget[]
}

export type DataFetchResult = Effect.Effect<
  {
    value: string
    source: DataSourceTarget
  },
  Cause.UnknownException
>
