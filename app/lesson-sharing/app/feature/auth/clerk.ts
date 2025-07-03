import { clerkMiddleware } from "@hono/clerk-auth"
import { Context, Effect, Layer } from "@totto/function/effect"
import { env } from "hono/adapter"
import { getContext } from "hono/context-storage"
import { createMiddleware } from "hono/factory"
import { AuthMiddlewares } from "../auth"

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
