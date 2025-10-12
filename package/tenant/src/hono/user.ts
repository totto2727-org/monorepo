import { Context, Layer, Option } from "@totto/function/effect"
import { getContext } from "hono/context-storage"
import type { schema } from "../schema/user.js"
import type { Env } from "./env.js"

const UserClass: Context.TagClass<User, "User", () => typeof schema.Type> =
  Context.Tag("User")()

export class User extends UserClass {}

export const live = Layer.succeed(User, () => {
  return Option.getOrThrow(Option.fromNullable(getContext<Env>().var.user))
})
