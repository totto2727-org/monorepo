import { Context, Layer, Option } from "@totto/function/effect"
import { getContext } from "hono/context-storage"
import type { AnyDrizzleD1Database } from "./../db/type.js"
import type { Env } from "./env.js"

export class TenantDatabase extends Context.Tag(
  "@package/tenant/hono/db/TenantDatabase",
)<TenantDatabase, () => AnyDrizzleD1Database>() {}

export const live = Layer.succeed(TenantDatabase, () =>
  Option.getOrThrow(Option.fromNullable(getContext<Env>().var.tenantDatabase)),
)

export class TenantDatabaseInitializer extends Context.Tag(
  "@package/tenant/hono/db/TenantDatabaseInitializer",
)<TenantDatabaseInitializer, () => void>() {}

export function makeTenantDatabaseInitializer(
  initializeDatabase: () => AnyDrizzleD1Database,
) {
  return Layer.succeed(TenantDatabaseInitializer, () => {
    getContext<Env>().set("tenantDatabase", initializeDatabase())
  })
}
