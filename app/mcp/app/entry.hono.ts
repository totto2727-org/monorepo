import { StreamableHTTPTransport } from "@hono/mcp"
import { Hono } from "hono"
import { logger } from "hono/logger"
import { createMcpServer } from "#@/mcp-server.js"

export const app = new Hono<{ Bindings: Cloudflare.Env }>()
  .use(logger())
  .all("/api/mcp/effect", async (c) => {
    const mcpServer = createMcpServer(c.env)
    const transport = new StreamableHTTPTransport()
    await mcpServer.connect(transport)
    return transport.handleRequest(c)
  })
