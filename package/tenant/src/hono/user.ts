// biome-ignore lint/correctness/noUnusedImports: required
import type { Brand } from "@totto/function/effect"

import { Context, Effect, Layer, type Option } from "@totto/function/effect"
import type { User as UserSchema } from "../schema.js"
import * as HonoContext from "./context.js"

export class User extends Context.Tag("@package/tenant/hono/user/User")<
  User,
  () => Option.Option<typeof UserSchema.schema.Type>
>() {}

export const live = Layer.effect(
  User,
  Effect.gen(function* () {
    const context = yield* HonoContext.Context
    return () => context().var.user
  }),
)
