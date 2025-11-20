import type { CloudflareAccessVariables } from "@hono/cloudflare-access"
import {
  Context as ContextEffect,
  Layer,
  type Option,
} from "@totto/function/effect"
import type { Context as HonoContext } from "hono"
import { getContext } from "hono/context-storage"
import type { AnyDrizzleD1Database } from "../db/type.js"
import type * as User from "../schema/user.js"

export type Env = {
  Variables: {
    tenantDatabase: AnyDrizzleD1Database
    user: Option.Option<typeof User.schema.Type>
  } & CloudflareAccessVariables
}

export class Context extends ContextEffect.Tag(
  "@package/tenant/hono/context/Context",
)<Context, () => HonoContext<Env>>() {}

export const live = Layer.succeed(Context, () => getContext<Env>().set)
