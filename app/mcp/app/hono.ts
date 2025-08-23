import type { Context as HonoContext } from "hono"
import { createFactory } from "hono/factory"
import { useRequestContext as useHonoRequestContext } from "hono/jsx-renderer"
import type { Env as EnvForOAuth } from "mcp-oauth-cloudflare-access"
import type { Database } from "./database.js"

export type Env = {
  Bindings: Cloudflare.Env & EnvForOAuth
  Variables: {
    db: Database
  }
}

export type Context = HonoContext<Env>

export const factory = createFactory<Env>()

export function useRequestContext() {
  return useHonoRequestContext<Env>()
}
