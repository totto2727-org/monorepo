import { Hono } from "hono"
import { jsxRenderer } from "hono/jsx-renderer"
import { logger } from "hono/logger"
import { mcpOAuthMiddleware } from "mcp-oauth-cloudflare-access"
import * as DataBase from "./feature/database.js"
import type { Env } from "./feature/hono.js"
import * as McpHandler from "./feature/mcp/handler.js"
import * as Layout from "./feature/ui/layout.js"
import * as DataSource from "./route/app/admin/data-source/endpoint.js"
import * as AdminEndpoint from "./route/app/admin/endpoint.js"
import * as AdminLayout from "./route/app/admin/layout.js"
import * as McpTool from "./route/app/admin/mcp-tool/endpoint.js"

const baseApp = new Hono<Env>().use(logger()).use("*", (c, next) => {
  c.set("db", DataBase.create(c.env.DB))
  return next()
})

export const mcpApp = baseApp
  .use("*", mcpOAuthMiddleware)
  .all("/api/mcp", ...McpHandler.mcpHandler)

export const adminApp = baseApp
  .get("/app/*", jsxRenderer(Layout.Layout))
  .get(
    "/app/admin/*",
    jsxRenderer(({ children, Layout }) => (
      <Layout>
        <AdminLayout.AdminLayout>{children}</AdminLayout.AdminLayout>
      </Layout>
    )),
  )
  .get("/app/admin", async (c) => {
    return c.render(<AdminEndpoint.Dashboard />)
  })
  .get("/app/admin/mcp-tool", ...McpTool.getHandler)
  .post("/app/admin/mcp-tool", ...McpTool.postHandler)
  .delete("/app/admin/mcp-tool", ...McpTool.deleteHandler)
  .get("/app/admin/data-source", ...DataSource.getHandler)
  .post("/app/admin/data-source", ...DataSource.postHandler)
  .delete("/app/admin/data-source", ...DataSource.deleteHandler)
  .use("*", mcpOAuthMiddleware)
