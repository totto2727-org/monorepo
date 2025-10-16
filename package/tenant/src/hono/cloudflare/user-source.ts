import { Context, Layer } from "@totto/function/effect"
import { getContext } from "hono/context-storage"
import type { Env } from "../env.js"

const UserSourceClass: Context.TagClass<
  UserSource,
  "UserSource",
  () => {
    id?: string
    organizationIDArray: string[]
  }
> = Context.Tag("UserSource")()

export class UserSource extends UserSourceClass {}

export function devLive(user: {
  id?: string
  organizationIDArray: string[]
}): Layer.Layer<UserSource, never, never> {
  return Layer.succeed(UserSource, () => user)
}

export const live = Layer.succeed(UserSource, () => {
  const payload = getContext<Env>().var.accessPayload
  return {
    id: payload?.sub,
    // @ts-expect-error -- デフォルトのpayloadに存在しないため
    organizationIDArray: payload?.groups ?? [],
  }
})
