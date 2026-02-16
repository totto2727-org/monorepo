import { parseFeed } from '@mikaelporttila/rss'
import { Effect } from '@totto2727/fp/effect'
import { HttpClient } from '@totto2727/fp/effect/platform'

export const makeRSSFetchClient = Effect.gen(function* () {
  const client = yield* HttpClient.HttpClient

  return Effect.fn(function* (feedURL: string) {
    const response = yield* client.get(feedURL)
    const text = yield* response.text
    return yield* Effect.tryPromise(() => parseFeed(text))
  })
})
