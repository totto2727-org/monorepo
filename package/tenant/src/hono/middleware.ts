import { Context, Layer } from "@totto/function/effect"
import type { MiddlewareHandler } from "hono"
import { contextStorage } from "hono/context-storage"
import { createMiddleware } from "hono/factory"

export class AuthHonoMiddlewares extends Context.Tag("AuthHonoMiddlewares")<
  AuthHonoMiddlewares,
  {
    contextStorage: ReturnType<typeof contextStorage>
    base: MiddlewareHandler
    // requiredUserID: MiddlewareHandler
    // requiredOrgID: MiddlewareHandler
  }
>() {}

export const devMiddlewareLive = Layer.succeed(AuthHonoMiddlewares, {
  base: createMiddleware((_, next) => {
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
