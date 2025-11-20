import { STATUS_CODE } from "@package/constant"
import { HTTPError, toHonoResponse } from "@package/error"
import { Effect, Option, Runtime } from "@totto/function/effect"
import { createMiddleware } from "hono/factory"
import { User } from "./user.js"

export const makeUnauthenticatedMiddleware = Effect.gen(function* () {
  const runtime = yield* Effect.runtime<User>()

  return createMiddleware((c, next) =>
    Effect.gen(function* () {
      const user = (yield* User)()
      if (Option.isNone(user)) {
        return c.json(
          ...toHonoResponse(new HTTPError(STATUS_CODE.UNAUTHORIZED)),
        )
      }
      yield* Effect.tryPromise(next)
      return
    }).pipe(Runtime.runPromise(runtime)),
  )
})
