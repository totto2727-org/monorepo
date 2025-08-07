import { Hono } from "hono"
import { jsxRenderer } from "hono/jsx-renderer"
import { logger } from "hono/logger"
import type { Env } from "./hono.js"
import { mcpHandler } from "./mcp/handler.js"
import {
  GetDataSource,
  PostDataSource,
} from "./route/app/admin/data-source/endpoint.js"
import { Dashboard } from "./route/app/admin/endpoint.js"
import { AdminLayout } from "./route/app/admin/layout.js"
import * as McpTool from "./route/app/admin/mcp-tool/endpoint.js"
import { Layout } from "./ui/layout.js"
import { createDatabase } from "./db.js"

export const app = new Hono<Env>()
  .use(logger())
  .use("*", (c, next) => {
    c.set("db", createDatabase(c.env.DB))
    return next()
  })
  .all("/api/mcp", ...mcpHandler)
  .get("/app/*", jsxRenderer(Layout))
  .get(
    "/app/admin/*",
    jsxRenderer(({ children, Layout }) => (
      <Layout>
        <AdminLayout>{children}</AdminLayout>
      </Layout>
    )),
  )
  .get("/app/admin", async (c) => {
    return c.render(<Dashboard />)
  })
  .get("/app/admin/mcp-tool", ...McpTool.getHandler)
  .post("/app/admin/mcp-tool", ...McpTool.postHandler)
  .get("/app/admin/data-source", async (c) => {
    return c.render(<GetDataSource />)
  })
  .post("/app/admin/data-source", (c) => c.render(<PostDataSource />))
