import { Hono } from "hono"
import { contextStorage } from "hono/context-storage"
import { logger } from "hono/logger"

export const app = new Hono()
  .use(contextStorage())
  .use(logger())
  .get("/api/hello", (c) => {
    return c.json({
      message: "Hello",
    })
  })
