import { Hono } from "hono"
import { jsxRenderer } from "hono/jsx-renderer"
import { logger } from "hono/logger"
import { createMcpHandler } from "#@/mcp/handler.js"
import { Layout } from "./admin/ui/layout.js"

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
  .get("/app/*", jsxRenderer(Layout))
  .get("/app/admin", async (c) => {
    return c.render(<div class="btn text-red-600">admin</div>)
  })
