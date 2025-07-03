import { Effect, Logger } from "@totto/function/effect"
import { appEffect, clerkCrenditionalLive } from "#@/entry.hono.js"
import { drizzleClientLive } from "./feature/db/drizzle"
import { inMemorySQLiteClientLive } from "./feature/db/sqlite"

const app = await Effect.gen(function* () {
  return yield* appEffect
}).pipe(
  Effect.provide(clerkCrenditionalLive),
  Effect.provide(drizzleClientLive),
  Effect.provide(inMemorySQLiteClientLive),
  Effect.provide(Logger.pretty),
  Effect.runPromise,
)

export default app
