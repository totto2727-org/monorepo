import { parseFeed } from '@mikaelporttila/rss'
import { Effect } from '@totto/function/effect'
import { HttpClient } from '@totto/function/effect/platform'

export const fetch = Effect.gen(function*  fetch() {
  const client = yield* HttpClient.HttpClient

  return Effect.fn(function*  fetch(feedURL: string) {
    const response = yield* client.get(feedURL)
    const text = yield* response.text
    return yield* Effect.tryPromise(() => parseFeed(text))
  })
})
