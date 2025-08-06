import { Hono } from "hono"
import { jsxRenderer } from "hono/jsx-renderer"
import { logger } from "hono/logger"
import { mcpHandler } from "./mcp/handler.js"
import {
  GetDataSources,
  PostDataSources,
} from "./route/app/admin/data-sources/endpoint.js"
import { Dashboard } from "./route/app/admin/endpoint.js"
import { AdminLayout } from "./route/app/admin/layout.js"
import {
  GetMcpTools,
  PostMcpTools,
} from "./route/app/admin/mcp-tools/endpoint.js"
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
  .get("/app/admin/mcp-tools", async (c) => {
    return c.render(<GetMcpTools />)
  })
  .post("/app/admin/api/mcp-tools", (c) => c.render(<PostMcpTools />))
  .get("/app/admin/data-sources", async (c) => {
    return c.render(<GetDataSources />)
  })
  .post("/app/admin/api/data-sources", (c) => c.render(<PostDataSources />))
