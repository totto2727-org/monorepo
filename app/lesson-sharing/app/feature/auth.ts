import { Context, Effect, Layer, Schema } from "@totto/function/effect"
import { Cuid } from "@totto/function/effect/id"
import type { MiddlewareHandler } from "hono"
import { createMiddleware } from "hono/factory"

export const userSchema = Schema.Struct({
  id: Cuid,
  orgID: Schema.Array(Cuid),
})
const user = Schema.decodePromise(userSchema)

export class AuthMiddlewares extends Context.Tag("AuthMiddlewares")<
  AuthMiddlewares,
  {
    baseMiddleware: MiddlewareHandler
    requiredUserID: MiddlewareHandler
    requiredOrgID: MiddlewareHandler
  }
>() {}

export const devAuthMiddlewaresLive = Layer.effect(
  AuthMiddlewares,
  Effect.gen(function* () {
    return {
      baseMiddleware: createMiddleware((_, next) => {
        return next()
      }),
      requiredOrgID: createMiddleware((_, next) => {
        return next()
      }),
      requiredUserID: createMiddleware((_, next) => {
        return next()
      }),
    }
  }),
)

export class AuthUseCase extends Context.Tag("AuthUseCase")<
  AuthUseCase,
  {
    getUser: () => Promise<typeof userSchema.Type>
  }
>() {}

export const devAuthUseCaseLive = Layer.effect(
  AuthUseCase,
  Effect.gen(function* () {
    return {
      getUser: () =>
        user({
          id: "b23twsc1ohaoy5ma6hw128hh",
          orgID: ["u84vo65ggfv2ms0o3pb2gdr2"],
        }),
    }
  }),
)
