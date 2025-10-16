import { Context, Effect, Layer, Option } from "@totto/function/effect"
import type { MiddlewareHandler } from "hono"
import { contextStorage } from "hono/context-storage"
import { createFactory } from "hono/factory"
import { HTTPException } from "hono/http-exception"
import type * as User from "../schema/user.js"
import type { Env } from "./env.js"
import { User as UserLayer } from "./user.js"

const factory = createFactory<Env>()

export const makeRequireUserMiddleware: Effect.Effect<
  MiddlewareHandler,
  never,
  UserLayer
> = Effect.gen(function* () {
  const getUser = yield* UserLayer
  return factory.createMiddleware((_, next) => {
    const user = getUser()
    if (Option.isNone(user)) {
      throw new HTTPException(401)
    }
    return next()
  })
})

export class AuthHonoMiddlewares extends Context.Tag("AuthHonoMiddlewares")<
  AuthHonoMiddlewares,
  {
    contextStorage: ReturnType<typeof contextStorage>
    base: MiddlewareHandler
    requireUser: MiddlewareHandler
  }
>() {}

export function devMiddlewareLive(
  user: Option.Option<typeof User.schema.Type>,
): Layer.Layer<AuthHonoMiddlewares, never, UserLayer> {
  return Layer.effect(
    AuthHonoMiddlewares,
    Effect.gen(function* () {
      const requireUserMiddleware = yield* makeRequireUserMiddleware

      return {
        base: factory.createMiddleware((c, next) => {
          c.set("user", user)
          return next()
        }),
        contextStorage: contextStorage(),
        requireUser: requireUserMiddleware,
      }
    }),
  )
}
