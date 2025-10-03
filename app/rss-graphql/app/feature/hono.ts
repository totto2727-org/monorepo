import type { Feed } from "@mikaelporttila/rss"
import type { Cause, Effect } from "@totto/function/effect"
import type { HttpClientError } from "@totto/function/effect/platform"
import type { Context as HonoContext } from "hono"
import { createFactory } from "hono/factory"

export type Env = {
  Bindings: Cloudflare.Env
  Variables: {
    rssFetcher: (
      feedURL: string,
    ) => Effect.Effect<
      Feed,
      Cause.UnknownException | HttpClientError.HttpClientError,
      never
    >
  }
}

export type Context = HonoContext<Env>

export const factory = createFactory<Env>()
