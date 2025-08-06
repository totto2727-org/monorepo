import type { Cause, Effect } from "@totto/function/effect"

export type DataSourceType = "text" | "firecrawl"

export type DataSourceTarget = {
  type: DataSourceType
  url: URL
}

export type DataSourceConfig = {
  mcpToolName: string
  dataSources: DataSourceTarget[]
}

export type DataFetchResult = Effect.Effect<
  {
    value: string
    source: DataSourceTarget
  },
  Cause.UnknownException
>
