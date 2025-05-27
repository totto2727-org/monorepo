import { Effect } from "@totto/function/effect"
import { Hono } from "hono"
import { logger } from "hono/logger"
import type { Env } from "./types/hono"

export const appEffect = Effect.gen(function* () {
  return new Hono<Env>()
    .use(logger())
    .use(async (c, next) => {
      c.set("MY_VAR_IN_VARIABLES", "My variable set in c.set")
      await next()
      c.header("X-Powered-By", "React Router and Hono")
    })
    .get("/api", (c) => {
      return c.json({
        message: "Hello",
        var: c.env.MY_VAR,
      })
    })
})
