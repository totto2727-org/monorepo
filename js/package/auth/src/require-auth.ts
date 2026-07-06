import { Predicate } from 'effect'
import type { Context as HonoContext, Env, MiddlewareHandler } from 'hono'

export interface RequireAuthVariables<User> {
  readonly user: User
}

interface MiddlewareFactory<E extends Env> {
  readonly createMiddleware: (handler: MiddlewareHandler<E>) => MiddlewareHandler<E>
}

export interface RequireAuthMiddlewareOptions<E extends Env & { Variables: RequireAuthVariables<User> }, User> {
  readonly factory: MiddlewareFactory<E>
  readonly onUnauthenticated: (ctx: HonoContext<E>) => Response | Promise<Response>
}

export const requireAuthMiddleware = <E extends Env & { Variables: RequireAuthVariables<User> }, User>(
  options: RequireAuthMiddlewareOptions<E, User>,
) =>
  options.factory.createMiddleware(async (ctx, next): Promise<Response> => {
    if (Predicate.isNullish(ctx.var.user)) {
      return await options.onUnauthenticated(ctx)
    }

    await next()
    return ctx.res
  })
