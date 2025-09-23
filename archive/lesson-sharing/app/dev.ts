// import {
//   clerkAuthMiddlewaresLive,
//   clerkAuthUseCaseLive,
//   clerkCrenditionalLive,
// } from "./feature/auth/clerk"
import { Effect, Logger } from "@totto/function/effect"
import { appEffect } from "#@/entry.hono.js"
import { devAuthMiddlewaresLive, devAuthUseCaseLive } from "./feature/auth.js"
import { drizzleClientLive } from "./feature/db/drizzle.js"
import { inMemorySQLiteClientLive } from "./feature/db/sqlite.js"

const app = await Effect.gen(function* () {
  return yield* appEffect
}).pipe(
  // Effect.provide(clerkAuthMiddlewaresLive),
  // Effect.provide(clerkCrenditionalLive),
  // Effect.provide(clerkAuthUseCaseLive),
  Effect.provide(devAuthMiddlewaresLive),
  Effect.provide(devAuthUseCaseLive),
  Effect.provide(drizzleClientLive),
  Effect.provide(inMemorySQLiteClientLive),
  Effect.provide(Logger.pretty),
  Effect.runPromise,
)

export default app
