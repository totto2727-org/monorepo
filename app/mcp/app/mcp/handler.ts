import { StreamableHTTPTransport } from "@hono/mcp"
import { factory } from "#@/hono.js"
import { createMcpServer } from "./server.js"
import type { McpServerConfig } from "./types.js"

export function createMcpHandler(
  configFn: (env: Cloudflare.Env) => McpServerConfig,
) {
  return factory.createHandlers(async (c) => {
    const config = configFn(c.env)
    const mcpServer = createMcpServer(config)
    const transport = new StreamableHTTPTransport()
    await mcpServer.connect(transport)
    return transport.handleRequest(c)
  })
}
