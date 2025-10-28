import { Context, Layer } from "@totto/function/effect"
import { getContext } from "hono/context-storage"
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
  () => {
    id?: string
    organizationIDArray: string[]
  }
> = Context.Tag("@package/tenant/hono/cloudflare-access/jwt/JWTUser")()

export class JWTUser extends JWTUserClass {}

export function jwtUserDev(user: {
  id?: string
  organizationIDArray: string[]
}): Layer.Layer<JWTUser, never, never> {
  return Layer.succeed(JWTUser, () => user)
}

export const jwtUserLive = Layer.succeed(JWTUser, () => {
  const payload = getContext<Env>().var.accessPayload
  return {
    id: payload?.sub,
    // @ts-expect-error -- デフォルトのpayloadに存在しないため
    organizationIDArray: payload?.groups ?? [],
  }
})
