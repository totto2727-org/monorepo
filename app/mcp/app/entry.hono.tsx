import { Hono } from "hono"
import { jsxRenderer } from "hono/jsx-renderer"
import { logger } from "hono/logger"
import { Layout } from "hono-ui/layout"
import { mcpOAuthMiddleware } from "mcp-oauth-cloudflare-access"
import tailwindcss from "../tailwind.css?raw"
import * as DataBase from "./feature/database.js"
import type { Env } from "./feature/hono.js"
import * as McpHandler from "./feature/mcp/handler.js"
import * as DataSource from "./route/app/admin/data-source/endpoint.js"
import * as AdminEndpoint from "./route/app/admin/endpoint.js"
import * as AdminLayout from "./route/app/admin/layout.js"
import * as McpTool from "./route/app/admin/mcp-tool/endpoint.js"

function createApp() {
  return new Hono<Env>().use(logger()).use("*", (c, next) => {
    c.set("db", DataBase.create(c.env.DB))
    return next()
  })
}

export const mcpApp = createApp()
  .use("*", mcpOAuthMiddleware)
  .all("/api/mcp", ...McpHandler.mcpHandler)

export const adminApp = createApp()
  .get(
    "/app/*",
    jsxRenderer(({ children }) => (
      <Layout css={tailwindcss} isProd={import.meta.env.PROD}>
        {children}
      </Layout>
    )),
  )
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
