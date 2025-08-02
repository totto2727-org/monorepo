import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js"
import { z } from "zod"
import type { McpServerConfig } from "./types.js"

export function createMcpServer(config: McpServerConfig) {
  const mcpServer = new McpServer({
    name: config.name,
    version: config.version,
  })

  mcpServer.registerTool(
    config.aiSearch.name,
    {
      description: config.aiSearch.description,
      inputSchema: {
        query: z.string().describe("Search query"),
        rewrite_query: z
          .boolean()
          .default(true)
          .describe("Enable query rewriting"),
      },
      title: config.aiSearch.title,
    },
    async ({ query, rewrite_query }) => {
      try {
        const result = await config.ai.autorag(config.autoRagName).aiSearch({
          query,
          rewrite_query: rewrite_query,
        })

        return {
          content: [
            {
              text: JSON.stringify(result, null, 2),
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

  return mcpServer
}
