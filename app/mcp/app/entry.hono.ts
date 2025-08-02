import { Hono } from "hono"
import { logger } from "hono/logger"
import { createMcpHandler } from "#@/mcp/handler.js"

const effectMcpHandler = createMcpHandler((env) => ({
  ai: env.AI,
  name: "effect-docs-mcp-server",
  sources: [
    {
      autoRagName: env.EFFECT_AUTO_RAG_NAME,
      description: "Search Effect documentation and generate AI responses",
      name: "search_ai_effect",
      title: "Effect Documentation Search",
    },
  ],
  version: "1.0.0",
}))

export const app = new Hono<{ Bindings: Cloudflare.Env }>()
  .use(logger())
  .all("/api/mcp", ...effectMcpHandler)
