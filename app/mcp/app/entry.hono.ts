import { Hono } from "hono"
import { logger } from "hono/logger"
import { createMcpHandler } from "#@/mcp/handler.js"

const mcpHandler = createMcpHandler((env) => ({
  ai: env.AI,
  name: "totto-docs-mcp-server",
  sources: [
    {
      description: "Search Effect documentation and generate AI responses",
      name: "search_ai_effect",
      target: "effect",
      title: "Effect Documentation Search",
    },
  ],
  version: "1.0.0",
}))

export const app = new Hono<{ Bindings: Cloudflare.Env }>()
  .use(logger())
  .all("/api/mcp", ...mcpHandler)
