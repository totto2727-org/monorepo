import { Effect } from "@totto/function/effect"
import { appEffect } from "#@/entry.hono.js"
import { DevDrizzleClientLive, DrizzleClient } from "#@/feature/db/drizzle.js"

const app = Effect.gen(function* () {
  yield* DrizzleClient
  return yield* appEffect
}).pipe(Effect.provide(DevDrizzleClientLive), Effect.runSync)

export default app
