import { createClient } from "@libsql/client/node"
import { Context, Effect, Layer } from "@totto/function/effect"
import { env } from "hono/adapter"
import { getContext } from "#@/feature/hono.js"

export class SQLiteCrenditional extends Context.Tag("SQLiteConfig")<
  SQLiteCrenditional,
  {
    readonly url: string
    readonly authToken: string
  }
>() {}

export const HonoSQLiteCrenditionalLive = Layer.effect(
  SQLiteCrenditional,
  // biome-ignore lint/correctness/useYield: <explanation>
  Effect.gen(function* () {
    return {
      authToken: env(getContext()).DATABASE_AUTH_TOKEN as string,
      url: env(getContext()).DATABASE_URL as string,
    }
  }),
)

// biome-ignore lint/correctness/useYield: <explanation>
export const inMemoryClientLive = Effect.gen(function* () {
  return createClient({
    url: "file::memory:?cache=shared",
  })
})

export const remoteClientLive = Effect.gen(function* () {
  const config = yield* SQLiteCrenditional
  return createClient({
    authToken: config.authToken,
    url: config.url,
  })
})
