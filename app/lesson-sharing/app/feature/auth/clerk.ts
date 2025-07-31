import { clerkMiddleware, getAuth } from "@hono/clerk-auth"
import {
  Context,
  Effect,
  Layer,
  Option,
  Predicate,
} from "@totto/function/effect"
import { eq, inArray } from "drizzle-orm"
import { env } from "hono/adapter"
import { getContext } from "hono/context-storage"
import { createMiddleware } from "hono/factory"
import { AuthMiddlewares, AuthUseCase } from "../auth.js"
import { DrizzleClient } from "../db/drizzle.js"
import { clerkOrganizationTable, clerkUserTable } from "../db/schema/table.js"
import * as User from "./user.js"

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
      requiredOrgID: createMiddleware((_, next) => {
        return next()
      }),
      requiredUserID: createMiddleware((_, next) => {
        return next()
      }),
    }
  }),
)

const getUserEffect = Effect.gen(function* () {
  const db = yield* DrizzleClient

  return Effect.fn(function* () {
    const auth = getAuth(getContext())
    const clerkUserID = yield* Option.fromNullable(auth?.userId)

    const [userDTOArray, organizationDTOArray] = yield* Effect.tryPromise(() =>
      db.batch([
        db
          .select({ id: clerkUserTable.userID })
          .from(clerkUserTable)
          .where(eq(clerkUserTable.clerkID, clerkUserID))
          .limit(1),
        db
          .select({ id: clerkOrganizationTable.organizationID })
          .from(clerkOrganizationTable)
          .where(
            inArray(
              clerkOrganizationTable.clerkID,
              Predicate.isNotNullable(auth?.orgId) ? [auth.orgId] : [],
            ),
          ),
      ]),
    )

    const userDTO = yield* Option.fromIterable(userDTOArray)

    return yield* User.fromDTO({
      organizationDTOArray,
      userDTO,
    })
  })
})

export const clerkAuthUseCaseLive = Layer.effect(
  AuthUseCase,
  Effect.gen(function* () {
    const getUser = yield* getUserEffect
    return {
      getUser: () => getUser().pipe(Effect.runPromise),
    }
  }),
)
