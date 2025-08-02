import { createFactory } from "hono/factory"

export const factory = createFactory<{ Bindings: Cloudflare.Env }>()
