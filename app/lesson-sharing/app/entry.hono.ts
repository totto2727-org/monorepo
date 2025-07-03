import { Effect } from "@totto/function/effect"
import { Hono } from "hono"
import { contextStorage } from "hono/context-storage"
import { logger } from "hono/logger"
import type { Env } from "#@/types/hono.js"
import { AuthMiddlewares } from "./feature/auth"

export const appEffect = Effect.gen(function* () {
  const authMiddlewares = yield* AuthMiddlewares

  return new Hono<Env>()
    .use(contextStorage())
    .use(logger())
    .use("/api", authMiddlewares.baseMiddleware)
    .get("/api/hello", (c) => {
      return c.json({
        message: "Hello",
      })
    })
})
