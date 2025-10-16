import { AppShell, SideMenu, SideMenuItem } from "@package/hono-ui/app-shell"
import * as Icon from "@package/hono-ui/icon"
import { Layout } from "@package/hono-ui/layout"
import { mcpOAuthMiddleware } from "@package/mcp-oauth-cloudflare-access"
import { Hono } from "hono"
import { jsxRenderer } from "hono/jsx-renderer"
import { logger } from "hono/logger"
import * as DataBase from "./feature/database.js"
import type { Env } from "./feature/hono.js"
import * as McpHandler from "./feature/mcp/handler.js"
import * as DataSource from "./route/app/admin/data-source/endpoint.js"
import * as AdminEndpoint from "./route/app/admin/endpoint.js"
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
  .get("/", (c) => c.redirect("/app/admin"))
  .get(
    "/app/*",
    jsxRenderer(({ children }) => (
      <Layout cssPath="../tailwind.css" isProd={import.meta.env.PROD}>
        <AppShell
          side={
            <SideMenu>
              <SideMenuItem href="/app/admin">
                <Icon.Dashboard ariaLabel="Dashboard Icon" />
                Dashboard
              </SideMenuItem>
              <SideMenuItem href="/app/admin/mcp-tool">
                <Icon.Tools ariaLabel="MCP Tools Icon" />
                MCP Tools
              </SideMenuItem>
              <SideMenuItem href="/app/admin/data-source">
                <Icon.Server ariaLabel="Data Sources Icon" />
                Data Sources
              </SideMenuItem>
            </SideMenu>
          }
          title="MCP Admin"
        >
          {children}
        </AppShell>
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
