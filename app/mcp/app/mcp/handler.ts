import { StreamableHTTPTransport } from "@hono/mcp"
import { factory } from "#@/hono.js"
import { createDatabase, schema } from "#@/db/db.js"
import { createMcpServer } from "./server.js"
import type { McpServerConfig } from "./types.js"

function createMcpHandler(configFn: (env: Cloudflare.Env, db: D1Database) => Promise<McpServerConfig>) {
  return factory.createHandlers(async (c) => {
    const config = await configFn(c.env, c.env.DB)
    const mcpServer = createMcpServer(c.env.AUTO_RAG_NAME, config)
    const transport = new StreamableHTTPTransport()
    await mcpServer.connect(transport)
    return transport.handleRequest(c)
  })
}

async function loadConfigFromDatabase(env: Cloudflare.Env, database: D1Database): Promise<McpServerConfig> {
  const db = createDatabase(database)
  const tools = await db.select().from(schema.mcpTool)
  
  return {
    ai: env.AI,
    name: "totto-docs-mcp-server",
    sources: tools.map(tool => ({
      description: tool.description,
      name: tool.name,
      title: tool.title,
    })),
    version: "1.0.0",
  }
}

export const mcpHandler = createMcpHandler(loadConfigFromDatabase)
