import { Context, Layer, Option } from "@totto/function/effect"
import { getContext } from "hono/context-storage"
import type { AnyDrizzleD1Database } from "./../db/type.js"
import type { Env } from "./env.js"

export class TenantDatabase extends Context.Tag("TenantDatabase")<
  TenantDatabase,
  () => AnyDrizzleD1Database
>() {}

export const live = Layer.succeed(TenantDatabase, () =>
  Option.getOrThrow(Option.fromNullable(getContext<Env>().var.tenantDatabase)),
)
