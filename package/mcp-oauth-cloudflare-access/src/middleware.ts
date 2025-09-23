import type { ExecutionContext } from "@cloudflare/workers-types"
import type { MiddlewareHandler } from "hono"
import { createMiddleware } from "hono/factory"
import { type Env, handleAccessRequest } from "./handler.js"

export const mcpOAuthMiddleware: MiddlewareHandler<{
  Bindings: Env
}> = createMiddleware((c) =>
  handleAccessRequest(c.req.raw, c.env, c.executionCtx as ExecutionContext),
)
