import { Context, Effect, Layer, Schema } from "@totto/function/effect"
import { Cuid } from "@totto/function/effect/id"
import type { MiddlewareHandler } from "hono"
import { createMiddleware } from "hono/factory"

export class AuthMiddlewares extends Context.Tag("AuthMiddlewares")<
  AuthMiddlewares,
  {
    baseMiddleware: MiddlewareHandler
  }
>() {}

export const devAuthMiddlewaresLive = Layer.effect(
  AuthMiddlewares,
  Effect.gen(function* () {
    return {
      baseMiddleware: createMiddleware((_, next) => {
        return next()
      }),
    }
  }),
)

export const userSchema = Schema.Struct({
  id: Cuid,
  orgID: Schema.Array(Cuid),
})

export const decodePromiseForUser = Schema.decodePromise(userSchema)

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
        decodePromiseForUser({
          id: "b23twsc1ohaoy5ma6hw128hh",
          orgID: ["u84vo65ggfv2ms0o3pb2gdr2"],
        }),
    }
  }),
)
