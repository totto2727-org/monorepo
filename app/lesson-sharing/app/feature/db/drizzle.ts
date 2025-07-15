import type { Client } from "@libsql/client"
import { Context, Effect, Layer } from "@totto/function/effect"
import { drizzle, type LibSQLDatabase } from "drizzle-orm/libsql"
import { SQLiteClient } from "./sqlite.js"

type DrizzleClientType = LibSQLDatabase<Record<string, never>> & {
  $client: Client
}

export class DrizzleClient extends Context.Tag("DrizzleClient")<
  DrizzleClient,
  DrizzleClientType
>() {}

export const drizzleClientLive = Layer.effect(
  DrizzleClient,
  Effect.gen(function* () {
    const sqlite = yield* SQLiteClient
    return drizzle({ client: sqlite })
  }),
)
