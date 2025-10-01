import { Hono } from "hono"
import { logger } from "hono/logger"
import type { Env } from "./feature/hono.js"

export const app = new Hono<Env>().use(logger())
