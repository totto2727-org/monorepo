import { Hono } from "hono"
import { logger } from "hono/logger"
import type { Env } from "./types/hono"

const app = new Hono<Env>()
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

export default app
