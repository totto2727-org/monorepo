import { Cause, Effect } from "@totto/function/effect"
import { FetchHttpClient, HttpClient } from "@totto/function/effect/platform"
import type { DataFetchResult, DataSourceTarget } from "./types.js"

function retrieveText(target: DataSourceTarget): DataFetchResult {
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

function retrieveFirecrawl(_target: DataSourceTarget): DataFetchResult {
  return Effect.fail(new Cause.UnknownException("TODO"))
}

export function retrieve(target: DataSourceTarget): DataFetchResult {
  switch (target.type) {
    case "text":
      return retrieveText(target)
    case "firecrawl":
      return retrieveFirecrawl(target)
  }
}
