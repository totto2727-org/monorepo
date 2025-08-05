import { StreamableHTTPTransport } from "@hono/mcp"
import { factory } from "#@/hono.js"
import { createMcpServer } from "./server.js"
import type { McpServerConfig } from "./types.js"

function createMcpHandler(configFn: (env: Cloudflare.Env) => McpServerConfig) {
  return factory.createHandlers(async (c) => {
    const config = configFn(c.env)
    const mcpServer = createMcpServer(c.env.AUTO_RAG_NAME, config)
    const transport = new StreamableHTTPTransport()
    await mcpServer.connect(transport)
    return transport.handleRequest(c)
  })
}

export const mcpHandler = createMcpHandler((env) => ({
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
