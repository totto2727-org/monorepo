import { Context, Layer, type Option } from "@totto/function/effect"
import { getContext } from "hono/context-storage"
import type { schema } from "../schema/user.js"
import type { Env } from "./env.js"

const UserClass: Context.TagClass<
  User,
  "@package/tenant/hono/user/User",
  () => Option.Option<typeof schema.Type>
> = Context.Tag("@package/tenant/hono/user/User")()

export class User extends UserClass {}

export const live = Layer.succeed(User, () => getContext<Env>().var.user)
