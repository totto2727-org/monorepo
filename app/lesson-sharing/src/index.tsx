import { Hono } from "hono"
import { logger } from "hono/logger"

const app = new Hono()

app.use("*", logger())

app.get("/health-check", (c) => {
  return c.text("OK")
})

export default app
