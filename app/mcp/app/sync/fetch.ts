import { Cause, Effect } from "@totto/function/effect"
import { FetchHttpClient, HttpClient } from "@totto/function/effect/platform"
import type { DataFetchResult, DataSourceTarget } from "./types.js"

function fetchText(target: DataSourceTarget): DataFetchResult {
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

function fetchFirecrawl(_target: DataSourceTarget): DataFetchResult {
  return Effect.fail(new Cause.UnknownException("TODO"))
}

export function fetch(target: DataSourceTarget): DataFetchResult {
  switch (target.type) {
    case "text":
      return fetchText(target)
    case "firecrawl":
      return fetchFirecrawl(target)
  }
}
