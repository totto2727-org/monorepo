import type { Client } from "@libsql/client"
import { Context, Effect, Layer } from "@totto/function/effect"
import { drizzle } from "drizzle-orm/libsql"
import * as schema from "./schema/table.js"
import { SQLiteClient } from "./sqlite.js"

function createDrizzleClient(client: Client) {
  return drizzle({ client, schema })
}

type DrizzleClientType = ReturnType<typeof createDrizzleClient>

export class DrizzleClient extends Context.Tag("DrizzleClient")<
  DrizzleClient,
  DrizzleClientType
>() {}

export const drizzleClientLive = Layer.effect(
  DrizzleClient,
  Effect.gen(function* () {
    const sqlite = yield* SQLiteClient
    return drizzle({ client: sqlite, schema })
  }),
)
