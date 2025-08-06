import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js"
import { z } from "zod"
import { createDatabase, schema } from "#@/db/db.js"
import type { McpServerConfig } from "./types.js"

export function createMcpServer(autoRagName: string, config: McpServerConfig) {
  const mcpServer = new McpServer({
    name: config.name,
    version: config.version,
  })

  for (const source of config.sources) {
    const toolName = `search_ai_${source.name}`

    mcpServer.registerTool(
      toolName,
      {
        description: source.description,
        inputSchema: {
          query: z.string().describe("Search query"),
          rewrite_query: z
            .boolean()
            .default(true)
            .describe("Enable query rewriting"),
        },
        title: source.title,
      },
      async ({ query, rewrite_query }) => {
        try {
          const result = await config.ai.autorag(autoRagName).aiSearch({
            filters: {
              key: "folder",
              type: "eq",
              value: `${source.name}/`,
            },
            query,
            rewrite_query: rewrite_query,
          })

          return {
            content: [
              {
                text: result.response,
                type: "text",
              },
            ],
          }
        } catch (error) {
          console.error("AI search failed:", error)
          return {
            content: [
              {
                text: "An error occurred while processing the search request",
                type: "text",
              },
            ],
          }
        }
      },
    )
  }

  return mcpServer
}
