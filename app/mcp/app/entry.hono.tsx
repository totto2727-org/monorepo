import { sql } from "drizzle-orm"
import { Hono } from "hono"
import { jsxRenderer } from "hono/jsx-renderer"
import { logger } from "hono/logger"
import { createDatabase, schema } from "./db/db.js"
import { mcpHandler } from "./mcp/handler.js"
import { DataSourcesManager } from "./route/app/admin/data-sources/endpoint.js"
import { Dashboard } from "./route/app/admin/endpoint.js"
import { AdminLayout } from "./route/app/admin/layout.js"
import { McpToolsManager } from "./route/app/admin/mcp-tools/endpoint.js"
import { Layout } from "./ui/layout.js"

export const app = new Hono<{ Bindings: Cloudflare.Env }>()
  .use(logger())
  .all("/api/mcp", ...mcpHandler)

  // API endpoints
  .post("/app/admin/api/mcp-tools", async (c) => {
    const db = createDatabase(c.env.DB)
    const body = await c.req.parseBody()

    try {
      await db.insert(schema.mcpTool).values({
        description: body.description as string,
        name: body.name as string,
        title: body.title as string,
      })

      // Return updated table
      const tools = await db
        .select()
        .from(schema.mcpTool)
        .orderBy(sql`created_at DESC`)

      return c.html(
        <div class="overflow-x-auto" id="tools-table">
          <table class="table table-zebra">
            <thead>
              <tr>
                <th>Name</th>
                <th>Title</th>
                <th>Used</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {tools.map((tool) => (
                <tr key={tool.name}>
                  <td>
                    <div class="font-mono text-sm">{tool.name}</div>
                  </td>
                  <td>
                    <div>
                      <div class="font-semibold">{tool.title}</div>
                      <div class="text-sm text-base-content/70 truncate max-w-xs">
                        {tool.description}
                      </div>
                    </div>
                  </td>
                  <td>
                    <div class="text-sm">
                      {(() => {
                        const now = new Date()
                        const lastUsed = new Date(tool.lastUsed)
                        const diffMs = now.getTime() - lastUsed.getTime()
                        const diffDays = Math.floor(
                          diffMs / (1000 * 60 * 60 * 24),
                        )
                        const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
                        const diffMinutes = Math.floor(diffMs / (1000 * 60))

                        if (diffDays > 0) return `${diffDays}d ago`
                        if (diffHours > 0) return `${diffHours}h ago`
                        if (diffMinutes > 0) return `${diffMinutes}m ago`
                        return "Just now"
                      })()}
                    </div>
                  </td>
                  <td>
                    <div class="flex gap-2">
                      <button class="btn btn-sm btn-outline" type="button">
                        Edit
                      </button>
                      <button
                        class="btn btn-sm btn-error btn-outline"
                        type="button"
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>,
      )
    } catch (error) {
      console.error("Failed to create MCP tool:", error)
      return c.text("Failed to create MCP tool", 500)
    }
  })

  .post("/app/admin/api/data-sources", async (c) => {
    const db = createDatabase(c.env.DB)
    const body = await c.req.parseBody()

    try {
      const mcpToolName = body.mcpToolName as string
      const newDataSources = []

      // Parse datasources array from form
      let index = 0
      while (body[`datasources[${index}][type]`]) {
        const type = body[`datasources[${index}][type]`] as string
        if (type === "text" || type === "firecrawl") {
          newDataSources.push({
            mcpToolName,
            type: type as "text" | "firecrawl",
            url: body[`datasources[${index}][url]`] as string,
          })
        }
        index++
      }

      // Insert all data sources
      for (const dataSource of newDataSources) {
        await db.insert(schema.dataSource).values(dataSource)
      }

      // Return updated table
      const rawDataSources = await db
        .select({
          createdAt: schema.dataSource.createdAt,
          mcpToolName: schema.dataSource.mcpToolName,
          type: schema.dataSource.type,
          url: schema.dataSource.url,
        })
        .from(schema.dataSource)
        .orderBy(schema.dataSource.mcpToolName, sql`created_at DESC`)

      // Group by mcp tool name
      const groupedDataSources = rawDataSources.reduce(
        (acc, source) => {
          const toolName = source.mcpToolName
          if (!acc[toolName]) {
            acc[toolName] = {
              createdAt: source.createdAt,
              id: `ds_${toolName}`,
              mcpToolName: toolName,
              sources: [],
              updatedAt: source.createdAt,
            }
          }
          acc[toolName].sources.push({
            type: source.type,
            url: source.url,
          })
          return acc
        },
        {} as Record<string, any>,
      )

      const finalDataSources = Object.values(groupedDataSources)

      return c.html(
        <div class="overflow-x-auto" id="datasources-table">
          <table class="table table-zebra">
            <thead>
              <tr>
                <th>ID</th>
                <th>MCP Tool</th>
                <th>Sources</th>
                <th>Updated</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {finalDataSources.map((ds: any) => (
                <tr key={ds.id}>
                  <td>
                    <div class="font-mono text-sm">{ds.id}</div>
                  </td>
                  <td>
                    <div class="badge badge-outline">{ds.mcpToolName}</div>
                  </td>
                  <td>
                    <div class="space-y-1">
                      {ds.sources.map((source: any, index: number) => (
                        <div
                          class="flex items-center gap-2"
                          key={`${ds.id}-source-${index}`}
                        >
                          <div class="badge badge-sm">{source.type}</div>
                          <div class="text-sm text-base-content/70 truncate max-w-xs">
                            {source.url}
                          </div>
                        </div>
                      ))}
                    </div>
                  </td>
                  <td>
                    <div class="text-sm">
                      {(() => {
                        const now = new Date()
                        const updatedAt = new Date(ds.updatedAt)
                        const diffMs = now.getTime() - updatedAt.getTime()
                        const diffDays = Math.floor(
                          diffMs / (1000 * 60 * 60 * 24),
                        )
                        const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
                        const diffMinutes = Math.floor(diffMs / (1000 * 60))

                        if (diffDays > 0) return `${diffDays}d ago`
                        if (diffHours > 0) return `${diffHours}h ago`
                        if (diffMinutes > 0) return `${diffMinutes}m ago`
                        return "Just now"
                      })()}
                    </div>
                  </td>
                  <td>
                    <div class="flex gap-2">
                      <button class="btn btn-sm btn-outline" type="button">
                        Edit
                      </button>
                      <button
                        class="btn btn-sm btn-error btn-outline"
                        type="button"
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>,
      )
    } catch (error) {
      console.error("Failed to create data sources:", error)
      return c.text("Failed to create data sources", 500)
    }
  })
  .get("/app/*", jsxRenderer(Layout))
  .get("/app/admin", async (c) => {
    return c.render(<AdminLayout>{await Dashboard(c)}</AdminLayout>)
  })
  .get("/app/admin/mcp-tools", async (c) => {
    return c.render(<AdminLayout>{await McpToolsManager(c)}</AdminLayout>)
  })
  .get("/app/admin/data-sources", async (c) => {
    return c.render(<AdminLayout>{await DataSourcesManager(c)}</AdminLayout>)
  })
