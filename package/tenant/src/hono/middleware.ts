import { Context, Effect, Option } from "@totto/function/effect"
import type { MiddlewareHandler } from "hono"
import type { contextStorage } from "hono/context-storage"
import { createFactory } from "hono/factory"
import { HTTPException } from "hono/http-exception"
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
