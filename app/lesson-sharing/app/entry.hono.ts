import { clerkMiddleware } from "@hono/clerk-auth"
import { Effect } from "@totto/function/effect"
import { Hono } from "hono"
import { env } from "hono/adapter"
import { contextStorage } from "hono/context-storage"
import { logger } from "hono/logger"
import { getContext } from "#@/feature/hono.js"
import type { Env } from "#@/types/hono.js"

export const appEffect = Effect.gen(function* () {
  return new Hono<Env>()
    .use(contextStorage())
    .use(logger())
    .use("/api", (...args) =>
      clerkMiddleware({
        publishableKey: env(getContext()).VITE_CLERK_PUBLISHABLE_KEY,
        secretKey: env(getContext()).CLERK_SECRET_KEY,
      })(...args),
    )
    .get("/api/hello", (c) => {
      return c.json({
        message: "Hello",
      })
    })
})
