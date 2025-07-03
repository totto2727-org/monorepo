import { clerkMiddleware, getAuth } from "@hono/clerk-auth"
import { Context, Effect, Layer, Predicate } from "@totto/function/effect"
import {
  CuidState,
  DateTimes,
  GetRandomValues,
  makeCuid,
} from "@totto/function/effect/id"
import { env } from "hono/adapter"
import { getContext } from "hono/context-storage"
import { createMiddleware } from "hono/factory"
import { HTTPException } from "hono/http-exception"
import { AuthMiddlewares, AuthUseCase, decodePromiseForUser } from "../auth"

class ClerkCrenditional extends Context.Tag("ClerkCrenditional")<
  ClerkCrenditional,
  {
    getCreanditional: () => {
      readonly publishableKey: string
      readonly secretKey: string
    }
  }
>() {}

export const clerkCrenditionalLive = Layer.effect(
  ClerkCrenditional,
  Effect.gen(function* () {
    return {
      getCreanditional: () => ({
        publishableKey: env(getContext()).VITE_CLERK_PUBLISHABLE_KEY as string,
        secretKey: env(getContext()).CLERK_SECRET_KEY as string,
      }),
    }
  }),
)

export const clerkAuthMiddlewaresLive = Layer.effect(
  AuthMiddlewares,
  Effect.gen(function* () {
    const { getCreanditional } = yield* ClerkCrenditional

    return {
      baseMiddleware: createMiddleware((...args) => {
        const config = getCreanditional()
        return clerkMiddleware({
          publishableKey: config.publishableKey,
          secretKey: config.secretKey,
        })(...args)
      }),
    }
  }),
)

export const clerkAuthUseCaseLive = Layer.effect(
  AuthUseCase,
  Effect.gen(function* () {
    return {
      getUser: async () => {
        const auth = getAuth(getContext())
        if (Predicate.isNullable(auth) || Predicate.isNullable(auth.userId)) {
          throw new HTTPException(401)
        }

        const id = await makeCuid.pipe(
          Effect.provide(CuidState.layer("my-environment")),
          Effect.provide([GetRandomValues.CryptoRandom, DateTimes.Default]),
          Effect.runPromise,
        )
        return decodePromiseForUser({
          id,
          orgID: auth.orgId ? [auth.orgId] : [],
        })
      },
    }
  }),
)
