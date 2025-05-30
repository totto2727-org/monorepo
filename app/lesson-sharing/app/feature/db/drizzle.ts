import type { Client } from "@libsql/client"
import { Context, Effect, Layer } from "@totto/function/effect"
import { drizzle, type LibSQLDatabase } from "drizzle-orm/libsql"
import { inMemoryClientLive, remoteClientLive } from "./sqlite"

type DrizzleClientType = LibSQLDatabase<Record<string, never>> & {
  $client: Client
}

export class DrizzleClient extends Context.Tag("DrizzleClient")<
  DrizzleClient,
  { readonly next: DrizzleClientType }
>() {}

export const DevDrizzleClientLive = Layer.effect(
  DrizzleClient,
  Effect.gen(function* () {
    const sqlite = yield* inMemoryClientLive
    return {
      next: drizzle({ client: sqlite }),
    }
  }),
)

export const ProdDrizzleClientLive = Layer.effect(
  DrizzleClient,
  Effect.gen(function* () {
    const sqlite = yield* remoteClientLive
    return {
      next: drizzle({ client: sqlite }),
    }
  }),
)
