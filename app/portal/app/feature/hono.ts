import type { Context as HonoContext } from "hono"
import { createFactory } from "hono/factory"

export type Env = {
  Bindings: Cloudflare.Env
  Variables: {}
}

export type Context = HonoContext<Env>

export const factory = createFactory<Env>()
