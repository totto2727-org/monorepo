import type { ExecutionContext } from "@cloudflare/workers-types"
import { createMiddleware } from "hono/factory"
import { type Env, handleAccessRequest } from "./handler.js"

export const mcpOAuthMiddleware = createMiddleware<{
  Bindings: Env
}>((c) =>
  handleAccessRequest(c.req.raw, c.env, c.executionCtx as ExecutionContext),
)
