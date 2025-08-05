import { Hono } from "hono"
import { jsxRenderer } from "hono/jsx-renderer"
import { logger } from "hono/logger"
import { createMcpHandler } from "#@/mcp/handler.js"
import { Layout } from "./admin/ui/layout.js"

const mcpHandler = createMcpHandler((env) => ({
  ai: env.AI,
  name: "totto-docs-mcp-server",
  sources: [
    {
      description: "Search Effect documentation and generate AI responses",
      name: "search_ai_effect",
      target: "effect",
      title: "Effect Documentation Search",
    },
  ],
  version: "1.0.0",
}))

import { Dashboard } from "./admin/pages/dashboard.js"
// Admin page routes
import { AdminLayout } from "./admin/pages/layout.js"
import { ServerConfig } from "./admin/pages/server.js"
import { ToolsManager } from "./admin/pages/tools.js"

export const app = new Hono<{ Bindings: Cloudflare.Env }>()
  .use(logger())
  .all("/api/mcp", ...mcpHandler)
  .get("/app/*", jsxRenderer(Layout))
  .get("/app/admin", async (c) => {
    return c.render(
      <AdminLayout>
        <Dashboard />
      </AdminLayout>,
    )
  })
  .get("/app/admin/server", async (c) => {
    return c.render(
      <AdminLayout>
        <ServerConfig />
      </AdminLayout>,
    )
  })
  .get("/app/admin/tools", async (c) => {
    return c.render(
      <AdminLayout>
        <ToolsManager />
      </AdminLayout>,
    )
  })
  .get("/app/admin/system", async (c) => {
    return c.render(
      <AdminLayout>
        <div class="space-y-6">
          <h1 class="text-3xl font-bold">システム設定</h1>
          <div class="card bg-base-100 shadow-lg">
            <div class="card-body">
              <h2 class="card-title">準備中</h2>
              <p>この機能は現在開発中です。</p>
            </div>
          </div>
        </div>
      </AdminLayout>,
    )
  })
