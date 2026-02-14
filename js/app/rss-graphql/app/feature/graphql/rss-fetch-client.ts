import { parseFeed } from '@mikaelporttila/rss'
import { Effect } from '@package/function/effect'
import { HttpClient } from '@package/function/effect/platform'

export const makeRSSFetchClient = Effect.gen(function* () {
  const client = yield* HttpClient.HttpClient

  return Effect.fn(function* (feedURL: string) {
    const response = yield* client.get(feedURL)
    const text = yield* response.text
    return yield* Effect.tryPromise(() => parseFeed(text))
  })
})
