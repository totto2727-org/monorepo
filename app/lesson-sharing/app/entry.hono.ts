import { Effect } from "@totto/function/effect"
import { Hono } from "hono"
import { contextStorage } from "hono/context-storage"
import { createFactory } from "hono/factory"
import { logger } from "hono/logger"
import type { Env } from "#@/types/hono.js"
import { AuthMiddlewares, AuthUseCase } from "./feature/auth.js"

const factory = createFactory()

const getUserHandlerLive = Effect.gen(function* () {
  const authUseCase = yield* AuthUseCase
  return factory.createHandlers(async (c) => {
    const user = await authUseCase.getUser()
    return c.json(user)
  })
})

export const appEffect = Effect.gen(function* () {
  const authMiddlewares = yield* AuthMiddlewares
  const getUserHandler = yield* getUserHandlerLive

  return new Hono<Env>()
    .use(contextStorage())
    .use(logger())
    .get("/api/hello", (c) => {
      return c.json({
        message: "Hello",
      })
    })
    .use("*", authMiddlewares.baseMiddleware)
    .get("/api/user", ...getUserHandler)
})
