import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js"
import { z } from "zod"

export function createMcpServer(env: Cloudflare.Env) {
  const mcpServer = new McpServer({
    name: "cloudflare-autorag-mcp-server",
    version: "1.0.0",
  })

  // Effect Documentation AI Search tool implementation
  mcpServer.registerTool(
    "search_effect_docs_by_ai",
    {
      description: "Effect ドキュメントを検索し、AI回答を生成する",
      inputSchema: {
        query: z.string().describe("検索クエリ"),
        rewrite_query: z
          .boolean()
          .default(true)
          .describe("クエリの書き換えを有効にする"),
        stream: z
          .boolean()
          .default(true)
          .describe("ストリーミングレスポンスを使用する"),
      },
      title: "Effect Documentation Search",
    },
    async ({ query, rewrite_query, stream }) => {
      try {
        const result = await env.AI.autorag(env.AUTO_RAG_NAME).aiSearch({
          query,
          rewrite_query: rewrite_query ?? true,
          stream: stream ?? true,
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
        return {
          content: [
            {
              text: `エラーが発生しました: ${error instanceof Error ? error.message : String(error)}`,
              type: "text",
            },
          ],
        }
      }
    },
  )

  return mcpServer
}
