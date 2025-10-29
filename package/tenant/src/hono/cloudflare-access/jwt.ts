import { Context, Layer, Option } from "@totto/function/effect"
import { getContext } from "hono/context-storage"
import * as JWTUserSchema from "../../schema/jwt-user.js"
import type { Env } from "../env.js"

const ApplicationAudienceClass: Context.TagClass<
  ApplicationAudience,
  "@package/tenant/hono/cloudflare-access/jwt/ApplicationAudience",
  () => string
> = Context.Tag(
  "@package/tenant/hono/cloudflare-access/jwt/ApplicationAudience",
)()

export class ApplicationAudience extends ApplicationAudienceClass {}

export const applicationAudienceLive = (fn: () => string) =>
  Layer.succeed(ApplicationAudience, fn)

export const applicationAudienceDev = (aud: string) =>
  Layer.succeed(ApplicationAudience, () => aud)

const JWTAudienceClass: Context.TagClass<
  JWTAudience,
  "@package/tenant/hono/cloudflare-access/jwt/JWTAudience",
  () => string[]
> = Context.Tag("@package/tenant/hono/cloudflare-access/jwt/JWTAudience")()

export class JWTAudience extends JWTAudienceClass {}

export const jwtAudienceDev = (aud: string[]) =>
  Layer.succeed(JWTAudience, () => aud)

export const jwtAudienceLive = Layer.succeed(
  JWTAudience,
  () => getContext<Env>().var.accessPayload.aud,
)

const JWTUserClass: Context.TagClass<
  JWTUser,
  "@package/tenant/hono/cloudflare-access/jwt/JWTUser",
  () => Option.Option<typeof JWTUserSchema.schema.Type>
> = Context.Tag("@package/tenant/hono/cloudflare-access/jwt/JWTUser")()

export class JWTUser extends JWTUserClass {}

export function jwtUserDev(
  user: Option.Option<typeof JWTUserSchema.schema.Type>,
): Layer.Layer<JWTUser, never, never> {
  return Layer.succeed(JWTUser, () => user)
}

export const jwtUserLive = Layer.succeed(JWTUser, () => {
  const payload = getContext<Env>().var.accessPayload

  return Option.some(
    JWTUserSchema.make({
      email: payload?.email ?? "",
      id: payload?.sub ?? "",
      name:
        // @ts-expect-error -- default payload doesn't have groups
        payload?.name ?? //
        payload?.email ??
        "",
      organizationArray:
        // @ts-expect-error -- default payload doesn't have groups
        payload?.groups?.map((group) => ({
          id: group,
          name: group,
        })) ?? [],
    }),
  )
})
