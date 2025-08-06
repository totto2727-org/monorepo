import { count, sql } from "drizzle-orm"
import { createDatabase, schema } from "#@/db.js"
import { useRequestContext } from "#@/hono.js"
import { ManagementCard } from "#@/ui/admin/card/management-card.js"
import { StatCard } from "#@/ui/admin/card/stat-card.js"
import { ServerIcon, ToolsIcon } from "#@/ui/icons/icon.js"

export async function Dashboard() {
  const c = useRequestContext()
  const db = createDatabase(c.env.DB)
  const [mcpToolsCountResult, dataSourcesCountResult, lastUpdatedResult] =
    await db.batch([
      db.select({ count: count() }).from(schema.mcpTool),
      db.select({ count: count() }).from(schema.dataSource),
      db
        .select({
          updatedAt: sql<string>`MAX(${schema.mcpTool.lastUsed})`.as(
            "updatedAt",
          ),
        })
        .from(schema.mcpTool),
    ])

  const stats = {
    dataSourcesCount: dataSourcesCountResult[0]?.count ?? 0,
    mcpToolsCount: mcpToolsCountResult[0]?.count ?? 0,
    updatedAt: lastUpdatedResult[0]?.updatedAt ?? "-",
  }

  return (
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">Admin Dashboard</h1>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <StatCard
          colorClass="text-primary"
          description="Registered search tools"
          title="MCP Tools"
          value={stats.mcpToolsCount}
        />
        <StatCard
          colorClass="text-secondary"
          description="Configured data sources"
          title="Data Sources"
          value={stats.dataSourcesCount}
        />
        <StatCard
          colorClass="text-info"
          description="System last updated"
          title="Updated"
          value={new Date(stats.updatedAt).toLocaleDateString("en-US")}
        />
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <ManagementCard
          description="Add, edit, and delete search tools"
          href="/app/admin/mcp-tools"
          icon={ToolsIcon}
          iconLabel="MCP Tools Icon"
          title="MCP Tools Management"
        />
        <ManagementCard
          description="Configure and manage data sources"
          href="/app/admin/data-sources"
          icon={ServerIcon}
          iconLabel="Data Sources Icon"
          title="Data Sources Management"
        />
      </div>
    </div>
  )
}
