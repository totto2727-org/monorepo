import { Hono } from "hono"
import { jsxRenderer } from "hono/jsx-renderer"
import { logger } from "hono/logger"
import * as DataBase from "./database.js"
import type { Env } from "./hono.js"
import * as McpHandler from "./mcp/handler.js"
import * as DataSource from "./route/app/admin/data-source/endpoint.js"
import * as AdminEndpoint from "./route/app/admin/endpoint.js"
import * as AdminLayout from "./route/app/admin/layout.js"
import * as McpTool from "./route/app/admin/mcp-tool/endpoint.js"
import * as Layout from "./ui/layout.js"

export const app = new Hono<Env>()
  .use(logger())
  .use("*", (c, next) => {
    c.set("db", DataBase.create(c.env.DB))
    return next()
  })
  .all("/api/mcp", ...McpHandler.mcpHandler)
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
  .get("/app/admin/data-source", ...DataSource.getHandler)
  .post("/app/admin/data-source", ...DataSource.postHandler)
