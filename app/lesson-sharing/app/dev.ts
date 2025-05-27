import { Effect } from "@totto/function/effect"
import { appEffect } from "#@/entry.hono.js"

const app = Effect.gen(function* () {
  return yield* appEffect
}).pipe(Effect.runSync)

export default app
