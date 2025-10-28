import { StreamableHTTPTransport } from "@hono/mcp"
import * as Table from "#@/feature/database/drizzle.js"
import * as DataBase from "#@/feature/database.js"
import * as Hono from "#@/feature/hono.js"
import * as Server from "./server.js"
import type * as McpServerConfig from "./type/mcp-server-config.js"

function createMcpHandler(
  configFn: (
    env: Cloudflare.Env,
    db: D1Database,
  ) => Promise<typeof McpServerConfig.schema.Type>,
) {
  return Hono.factory.createHandlers(async (c) => {
    const config = await configFn(c.env, c.env.DB)
    const mcpServer = Server.createMcpServer(c.env.AUTO_RAG_NAME, config)
    const transport = new StreamableHTTPTransport()
    await mcpServer.connect(transport)
    return transport.handleRequest(c)
  })
}

async function loadConfigFromDatabase(
  env: Cloudflare.Env,
  database: D1Database,
): Promise<typeof McpServerConfig.schema.Type> {
  const db = DataBase.create(database)
  const toolArray = await db.select().from(Table.mcpToolTable)

  return {
    ai: env.AI,
    name: "totto-docs-mcp-server",
    sources: toolArray.map((tool) => ({
      description: tool.description,
      name: tool.name,
      title: tool.title,
    })),
    version: "1.0.0",
  }
}

export const mcpHandler = createMcpHandler(loadConfigFromDatabase)
