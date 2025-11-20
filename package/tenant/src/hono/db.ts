import { Context, Effect, Layer, Option } from "@totto/function/effect"
import type { AnyDrizzleD1Database } from "./../db/type.js"
import * as HonoContext from "./context.js"

export class TenantDatabase extends Context.Tag(
  "@package/tenant/hono/db/TenantDatabase",
)<TenantDatabase, () => AnyDrizzleD1Database>() {}

export const live = Layer.effect(
  TenantDatabase,
  Effect.gen(function* () {
    const context = yield* HonoContext.Context
    return () =>
      Option.getOrThrow(Option.fromNullable(context().var.tenantDatabase))
  }),
)

export class TenantDatabaseInitializer extends Context.Tag(
  "@package/tenant/hono/db/TenantDatabaseInitializer",
)<
  TenantDatabaseInitializer,
  Effect.Effect<() => void, never, HonoContext.Context>
>() {}

export function makeTenantDatabaseInitializer(
  initializeDatabase: () => AnyDrizzleD1Database,
) {
  return Layer.succeed(
    TenantDatabaseInitializer,
    Effect.gen(function* () {
      const context = yield* HonoContext.Context
      return () => context().set("tenantDatabase", initializeDatabase())
    }),
  )
}
