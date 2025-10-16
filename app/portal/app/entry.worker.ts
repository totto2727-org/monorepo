import { Middleware } from "@monorepo/tenant/hono"
import {
  createStartHandler,
  defaultStreamHandler,
} from "@tanstack/react-start/server"
import { Effect, Option } from "@totto/function/effect"
import { Cuid } from "@totto/function/effect/id"
import { createApp } from "./entry.hono.jsx"

// https://github.com/TanStack/router/blob/main/packages/react-start/src/default-entry/server.ts
const fetch = createStartHandler(defaultStreamHandler)

const app = createApp
  .pipe(
    Effect.provide(
      Middleware.devMiddlewareLive(
        Option.some({
          id: Cuid.make("id"),
          organizationIDArray: [Cuid.make("org1"), Cuid.make("org2")],
        }),
      ),
    ),
    Effect.runSync,
  )
  .get("/", (c) => c.redirect("/app"))
  // Tanstack Startの仕様上、ルートを指定しないと常に404になる
  .mount("/", fetch)

export default app
