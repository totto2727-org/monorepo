import { Context, Effect, Layer, Option } from "@totto/function/effect"
import * as JWTUserSchema from "../../schema/jwt-user.js"
import * as HonoContext from "../context.js"

export class ApplicationAudience extends Context.Tag(
  "@package/tenant/hono/cloudflare-access/jwt/ApplicationAudience",
)<ApplicationAudience, () => string>() {}

export const applicationAudienceLive = (fn: () => string) =>
  Layer.effect(
    ApplicationAudience,
    // biome-ignore lint/correctness/useYield: required
    Effect.gen(function* () {
      return fn
    }),
  )

export const applicationAudienceDev = (aud: string) =>
  Layer.succeed(ApplicationAudience, () => aud)

export class JWTAudience extends Context.Tag(
  "@package/tenant/hono/cloudflare-access/jwt/JWTAudience",
)<JWTAudience, () => string[]>() {}

export const jwtAudienceDev = (aud: string[]) =>
  Layer.succeed(JWTAudience, () => aud)

export const jwtAudienceLive = Layer.effect(
  JWTAudience,
  Effect.gen(function* () {
    const context = yield* HonoContext.Context
    return () => context().var.accessPayload.aud
  }),
)

export class JWTUser extends Context.Tag(
  "@package/tenant/hono/cloudflare-access/jwt/JWTUser",
)<JWTUser, () => Option.Option<typeof JWTUserSchema.schema.Type>>() {}

export function jwtUserDev(
  user: Option.Option<typeof JWTUserSchema.schema.Type>,
): Layer.Layer<JWTUser, never, never> {
  return Layer.succeed(JWTUser, () => user)
}

export const jwtUserLive = Layer.effect(
  JWTUser,
  Effect.gen(function* () {
    const context = yield* HonoContext.Context

    return () => {
      const payload = context().var.accessPayload
      return Option.some(
        JWTUserSchema.make({
          email: payload?.email ?? "",
          id: payload?.sub ?? "",
          name:
            // @ts-expect-error -- default payload doesn't have groups
            payload?.name ?? payload?.email ?? "",
          organizationArray:
            // @ts-expect-error -- default payload doesn't have groups
            payload?.groups?.map((group) => ({
              id: group,
              name: group,
            })) ?? [],
        }),
      )
    }
  }),
)
