import type { Env as TenantEnv } from "@package/tenant/hono"
import { Layer, Option } from "@totto/function/effect"
import type { Context as HonoContext } from "hono"
import { getContext as getHonoContext } from "hono/context-storage"
import { createFactory } from "hono/factory"
import * as Drizzle from "./drizzle.js"
import { Database } from "./drizzle.js"

export type Env = {
  Bindings: Cloudflare.Env
  Variables: {
    database: Drizzle.Client
  }
} & TenantEnv.Env

export type Context = HonoContext<Env>

export const factory = createFactory<Env>()

export function getContext(): Context {
  return getHonoContext<Env>()
}

export const setupMiddleware = factory.createMiddleware((c, next) => {
  c.set("database", Drizzle.makeClient(c.env.DB))
  return next()
})

export const databaseLive = Layer.succeed(Database, () =>
  Option.getOrThrow(Option.fromNullable(getContext().var.database)),
)
