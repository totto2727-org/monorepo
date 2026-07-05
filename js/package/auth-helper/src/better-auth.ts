import { Effect, Option, Predicate, Schema } from 'effect'
import type { Context, Layer } from 'effect'
import type { Context as HonoContext, Env, MiddlewareHandler } from 'hono'

export interface BetterAuthUser {
  readonly email: string
  readonly id: string
}

export interface AuthUser {
  readonly email: string
  readonly id: string
}

export interface AuthVariables {
  readonly user: AuthUser
}

export interface OptionalAuthVariables {
  readonly user: AuthUser | null
}

export interface BetterAuthSetupVariables {
  readonly user: AuthUser | null
}

export interface BetterAuthSessionProvider {
  readonly api: {
    readonly getSession: (input: { readonly headers: Headers }) => Promise<{ readonly user: unknown } | null>
  }
}

export interface BetterAuthServiceDefinition<Identifier, Auth extends BetterAuthSessionProvider> {
  readonly Service: Context.Service<Identifier, Auth>
  readonly layer: Layer.Layer<Auth, unknown, unknown>
}

const BetterAuthUserPayload = Schema.Struct({
  email: Schema.String,
  id: Schema.String,
})

const decodeBetterAuthUserPayload = Schema.decodeUnknownOption(BetterAuthUserPayload)

export const toAuthUser = (user: BetterAuthUser): AuthUser => ({ email: user.email, id: user.id })

export const decodeBetterAuthUser = (value: unknown): BetterAuthUser | null =>
  Option.getOrNull(decodeBetterAuthUserPayload(value))

export const getBetterAuthUser = (auth: BetterAuthSessionProvider, headers: Headers) =>
  Effect.gen(function* () {
    const session = yield* Effect.tryPromise(() => auth.api.getSession({ headers }))
    if (Predicate.isNullish(session)) {
      return null
    }
    return decodeBetterAuthUser(session.user)
  })

export const getBetterAuthSessionUser = (auth: BetterAuthSessionProvider, headers: Headers) =>
  Effect.gen(function* () {
    const session = yield* Effect.tryPromise(() => auth.api.getSession({ headers }))
    return Predicate.isNullish(session) ? null : session.user
  })

const defaultMapUser = (user: unknown): AuthUser | null => {
  const decodedUser = decodeBetterAuthUser(user)
  return Predicate.isNullish(decodedUser) ? null : toAuthUser(decodedUser)
}

interface MiddlewareFactory<E extends Env> {
  readonly createMiddleware: (handler: MiddlewareHandler<E>) => MiddlewareHandler<E>
}

export interface BetterAuthSetupMiddlewareOptions<
  E extends Env & { Variables: BetterAuthSetupVariables },
  Identifier,
  Auth extends BetterAuthSessionProvider,
> {
  readonly factory: MiddlewareFactory<E>
  readonly runPromise: <A>(ctx: HonoContext<E>, effect: Effect.Effect<A, unknown, Identifier>) => Promise<A>
  readonly service: Context.Service<Identifier, Auth>
}

export const createBetterAuthSetupMiddleware = <
  E extends Env & { Variables: BetterAuthSetupVariables },
  Identifier,
  Auth extends BetterAuthSessionProvider,
>(
  options: BetterAuthSetupMiddlewareOptions<E, Identifier, Auth>,
) =>
  options.factory.createMiddleware((ctx, next) => {
    const effect = Effect.gen(function* () {
      const auth = yield* options.service
      const user = yield* getBetterAuthSessionUser(auth, ctx.req.raw.headers)
      ctx.set('user', Predicate.isNullish(user) ? null : defaultMapUser(user))
      yield* Effect.promise(() => next())
    })
    // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP middleware boundary executes request-scoped auth workflow.
    return options.runPromise(ctx, effect)
  })
