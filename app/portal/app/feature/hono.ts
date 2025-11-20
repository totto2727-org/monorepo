import type { Context as TenantContext } from "@package/tenant/hono"
import { Layer, Option } from "@totto/function/effect"
import {
  type Enforcer,
  newEnforcer,
  newModelFromString,
  StringAdapter,
} from "casbin"
import type { Context as HonoContext } from "hono"
import { getContext as getHonoContext } from "hono/context-storage"
import { createFactory } from "hono/factory"
import * as Drizzle from "./drizzle.js"
import { Database } from "./drizzle.js"

export type Env = {
  Bindings: Cloudflare.Env
  Variables: {
    database: Drizzle.Client
    enforcer: Enforcer
  }
} & TenantContext.Env

export type Context = HonoContext<Env>

export const factory = createFactory<Env>()

export function getContext(): Context {
  return getHonoContext<Env>()
}

export const setupMiddleware = factory.createMiddleware(async (c, next) => {
  c.set("database", Drizzle.makeClient(c.env.DB))
  c.set(
    "enforcer",
    await newEnforcer(
      newModelFromString(
        `
[request_definition]
r = sub, obj, act

[policy_definition]
p = sub, obj, act

[policy_effect]
e = some(where (p.eft == allow))

[matchers]
m = r.sub == p.sub && r.obj == p.obj && r.act == p.act
`,
      ),
      new StringAdapter(
        `
p, vju4b47777rul9ldlz6g4jat, data1, read
`,
      ),
    ),
  )
  return next()
})

export const databaseLive = Layer.succeed(Database, () =>
  Option.getOrThrow(Option.fromNullable(getContext().var.database)),
)
