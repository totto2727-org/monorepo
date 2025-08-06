import { Hono } from "hono"
import { jsxRenderer } from "hono/jsx-renderer"
import { logger } from "hono/logger"
import { mcpHandler } from "./mcp/handler.js"
import {
  GetDataSource,
  PostDataSource,
} from "./route/app/admin/data-source/endpoint.js"
import { Dashboard } from "./route/app/admin/endpoint.js"
import { AdminLayout } from "./route/app/admin/layout.js"
import { GetMcpTool, PostMcpTool } from "./route/app/admin/mcp-tool/endpoint.js"
import { Layout } from "./ui/layout.js"

export const app = new Hono<{ Bindings: Cloudflare.Env }>()
  .use(logger())
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
  .get("/app/admin/mcp-tool", async (c) => {
    return c.render(<GetMcpTool />)
  })
  .post("/app/admin/mcp-tool", (c) => c.render(<PostMcpTool />))
  .get("/app/admin/data-source", async (c) => {
    return c.render(<GetDataSource />)
  })
  .post("/app/admin/data-source", (c) => c.render(<PostDataSource />))
