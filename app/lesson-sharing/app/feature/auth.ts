import { Context } from "@totto/function/effect"
import type { MiddlewareHandler } from "hono"

export class AuthMiddlewares extends Context.Tag("AuthMiddlewares")<
  AuthMiddlewares,
  {
    baseMiddleware: MiddlewareHandler
  }
>() {}
