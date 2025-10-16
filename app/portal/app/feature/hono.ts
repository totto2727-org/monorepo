import type { Env as TenantEnv } from "@package/tenant/hono"
import type { Context as HonoContext } from "hono"
import { getContext as getHonoContext } from "hono/context-storage"
import { createFactory } from "hono/factory"

export type Env = {
  Bindings: Cloudflare.Env
  Variables: {}
} & TenantEnv.Env

export type Context = HonoContext<Env>

export const factory = createFactory<Env>()

export function getContext(): Context {
  return getHonoContext<Env>()
}
