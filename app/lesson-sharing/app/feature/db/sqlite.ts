import { type Client, createClient } from "@libsql/client"
import { Context, Effect, Layer } from "@totto/function/effect"
import { env } from "hono/adapter"
import { getContext } from "#@/feature/hono.js"

class SQLiteCrenditional extends Context.Tag("SQLiteConfig")<
  SQLiteCrenditional,
  {
    getCreanditional: () => {
      readonly url: string
      readonly authToken: string
    }
  }
>() {}

export const sqliteCrenditionalLive = Layer.effect(
  SQLiteCrenditional,
  Effect.gen(function* () {
    return {
      getCreanditional: () => ({
        authToken: env(getContext()).DATABASE_AUTH_TOKEN as string,
        url: env(getContext()).DATABASE_URL as string,
      }),
    }
  }),
)

export class SQLiteClient extends Context.Tag("SQLiteClient")<
  SQLiteClient,
  Client
>() {}

export const remoteSQLiteClientLive = Layer.effect(
  SQLiteClient,
  Effect.gen(function* () {
    const { getCreanditional } = yield* SQLiteCrenditional
    const config = getCreanditional()
    yield* Effect.logDebug("config", config)
    return createClient({
      authToken: config.authToken,
      url: config.url,
    })
  }),
)

export const inMemorySQLiteClientLive = Layer.effect(
  SQLiteClient,
  Effect.gen(function* () {
    const libSQL = yield* Effect.tryPromise(() => import("@libsql/client/node"))
    return libSQL.createClient({
      url: "file::memory:?cache=shared",
    })
  }),
)
