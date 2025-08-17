import { Cause, Effect } from "@totto/function/effect"
import { FetchHttpClient, HttpClient } from "@totto/function/effect/platform"
import type { DataFetchResult } from "./type/data-fetch-result.js"
import type * as DataSourceTarget from "./type/data-source-target.js"

function retrieveText(
  target: typeof DataSourceTarget.schema.Type,
): DataFetchResult {
  return Effect.gen(function* () {
    const httpClient = yield* HttpClient.HttpClient
    const response = yield* httpClient.get(target.url.toString())
    const value = yield* response.text
    return { source: target, value }
  }).pipe(
    Effect.catchAll((e) => Effect.fail(new Cause.UnknownException(e))),
    Effect.provide(FetchHttpClient.layer),
  )
}

function retrieveFirecrawl(
  _target: typeof DataSourceTarget.schema.Type,
): DataFetchResult {
  return Effect.fail(new Cause.UnknownException("TODO"))
}

export function retrieve(
  target: typeof DataSourceTarget.schema.Type,
): DataFetchResult {
  switch (target.type) {
    case "text":
      return retrieveText(target)
    case "firecrawl":
      return retrieveFirecrawl(target)
    default:
      return Effect.fail(
        new Cause.UnknownException(
          `Unknown data source type: ${JSON.stringify(target.type)}`,
        ),
      )
  }
}
