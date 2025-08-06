import { Hono } from "hono"
import { jsxRenderer } from "hono/jsx-renderer"
import { logger } from "hono/logger"
import { Dashboard } from "./admin/pages/dashboard.js"
import { DataSourcesManager } from "./admin/pages/data-sources.js"
import { AdminLayout } from "./admin/pages/layout.js"
import { McpToolsManager } from "./admin/pages/mcp-tools.js"
import { Layout } from "./admin/ui/layout.js"
import { mcpHandler } from "./mcp/handler.js"

export const app = new Hono<{ Bindings: Cloudflare.Env }>()
  .use(logger())
  .all("/api/mcp", ...mcpHandler)
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
