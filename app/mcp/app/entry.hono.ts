import { Hono } from "hono"
import { logger } from "hono/logger"
import { createMcpHandler } from "#@/mcp/handler.js"

const effectMcpHandler = createMcpHandler((env) => ({
  ai: env.AI,
  aiSearch: {
    description: "Search Effect documentation and generate AI responses",
    name: "search_effect_docs_by_ai",
    title: "Effect Documentation Search",
  },
  autoRagName: env.EFFECT_AUTO_RAG_NAME,
  name: "effect-docs-mcp-server",
  version: "1.0.0",
}))

export const app = new Hono<{ Bindings: Cloudflare.Env }>()
  .use(logger())
  .all("/api/mcp/effect", ...effectMcpHandler)
