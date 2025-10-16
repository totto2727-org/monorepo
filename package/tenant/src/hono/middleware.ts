import { Context, Layer, type Option } from "@totto/function/effect"
import type { MiddlewareHandler } from "hono"
import { contextStorage } from "hono/context-storage"
import { createMiddleware } from "hono/factory"
import type * as User from "../schema/user.js"
import type { Env } from "./env.js"

export class AuthHonoMiddlewares extends Context.Tag("AuthHonoMiddlewares")<
  AuthHonoMiddlewares,
  {
    contextStorage: ReturnType<typeof contextStorage>
    base: MiddlewareHandler
    // requiredUserID: MiddlewareHandler
    // requiredOrgID: MiddlewareHandler
  }
>() {}

export function devMiddlewareLive(
  user: Option.Option<typeof User.schema.Type>,
): Layer.Layer<AuthHonoMiddlewares, never, never> {
  return Layer.succeed(AuthHonoMiddlewares, {
    base: createMiddleware<Env>((c, next) => {
      c.set("user", user)
      return next()
    }),
    contextStorage: contextStorage(),
    // requiredOrgID: createMiddleware((_, next) => {
    //   return next()
    // }),
    // requiredUserID: createMiddleware((_, next) => {
    //   return next()
    // }),
  })
}
