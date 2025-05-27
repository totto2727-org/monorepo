import { clerkMiddleware } from "@hono/clerk-auth"
import { Effect } from "@totto/function/effect"
import { Hono } from "hono"
import { env } from "hono/adapter"
import { logger } from "hono/logger"
import type { Env } from "./types/hono"

export const appEffect = Effect.gen(function* () {
  return new Hono<Env>()
    .use(logger())
    .use("/api", (c, next) =>
      clerkMiddleware({
        publishableKey: env(c).VITE_CLERK_PUBLISHABLE_KEY,
        secretKey: env(c).CLERK_SECRET_KEY,
      })(c, next),
    )
    .get("/api/hello", (c) => {
      return c.json({
        message: "Hello",
      })
    })
})
