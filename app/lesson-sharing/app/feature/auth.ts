import { Context, Effect, Layer, Schema } from "@totto/function/effect"
import type { MiddlewareHandler } from "hono"
import { createMiddleware } from "hono/factory"
import * as User from "./auth/user.js"

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
    getUser: () => Promise<typeof User.schema.Type>
  }
>() {}

const decodeUser = Schema.decode(User.schema)
export const devAuthUseCaseLive = Layer.effect(
  AuthUseCase,
  Effect.gen(function* () {
    return {
      getUser: () =>
        decodeUser({
          id: "b23twsc1ohaoy5ma6hw128hh",
          orgID: ["u84vo65ggfv2ms0o3pb2gdr2"],
        }).pipe(Effect.runPromise),
    }
  }),
)
