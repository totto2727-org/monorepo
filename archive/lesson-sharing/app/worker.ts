import { Effect, Logger } from "@totto/function/effect"
import handle from "hono-react-router-adapter/cloudflare-workers"
import { appEffect } from "#@/entry.hono.js"
import { getLoadContext } from "#@/types/react-router.js"
import * as build from "../build/server/index.js"
import {
  clerkAuthMiddlewaresLive,
  clerkAuthUseCaseLive,
  clerkCrenditionalLive,
} from "./feature/auth/clerk.js"
import { drizzleClientLive } from "./feature/db/drizzle.js"
import {
  remoteSQLiteClientLive,
  sqliteCrenditionalLive,
} from "./feature/db/sqlite.js"

const app = await Effect.gen(function* () {
  return handle(build, yield* appEffect, { getLoadContext })
}).pipe(
  Effect.provide(clerkAuthMiddlewaresLive),
  Effect.provide(clerkCrenditionalLive),
  Effect.provide(clerkAuthUseCaseLive),
  Effect.provide(drizzleClientLive),
  Effect.provide(remoteSQLiteClientLive),
  Effect.provide(sqliteCrenditionalLive),
  Effect.provide(Logger.json),
  Effect.runPromise,
)

export default app
