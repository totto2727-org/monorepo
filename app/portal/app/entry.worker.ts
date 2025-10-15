import {
  createStartHandler,
  defaultStreamHandler,
} from "@tanstack/react-start/server"
import { createApp } from "./entry.hono.jsx"

// https://github.com/TanStack/router/blob/main/packages/react-start/src/default-entry/server.ts
const fetch = createStartHandler(defaultStreamHandler)

const app = createApp()
  .get("/", (c) => c.redirect("/app"))
  // Tanstack Startの仕様上、ルートを指定しないと常に404になる
  .mount("/", fetch)

export default app
