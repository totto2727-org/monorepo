import type { Context as HonoContext } from "hono"
import { createFactory } from "hono/factory"

export type Env = {
  Bindings: Cloudflare.Env
  // biome-ignore lint/complexity/noBannedTypes: 現時点では不要
  Variables: {}
}

export type Context = HonoContext<Env>

export const factory = createFactory<Env>()
