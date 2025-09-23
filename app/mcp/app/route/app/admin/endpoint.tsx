import { count, sql } from "drizzle-orm"
import * as DataBase from "#@/feature/database.js"
import * as Hono from "#@/feature/hono.js"
import * as ManagementCard from "#@/feature/ui/admin/card/management-card.js"
import * as StatCard from "#@/feature/ui/admin/card/stat-card.js"
import { H1Container } from "#@/feature/ui/admin/h1-container.js"
import * as Icon from "#@/feature/ui/icons/icon.js"

export async function Dashboard() {
  const c = Hono.useRequestContext()
  const db = DataBase.create(c.env.DB)
  const [mcpToolsCountResult, dataSourcesCountResult, lastUpdatedResult] =
    await db.batch([
      db.select({ count: count() }).from(DataBase.schema.mcpToolTable),
      db.select({ count: count() }).from(DataBase.schema.dataSourceTable),
      db
        .select({
          updatedAt:
            sql<string>`MAX(${DataBase.schema.mcpToolTable.lastUsed})`.as(
              "updatedAt",
            ),
        })
        .from(DataBase.schema.mcpToolTable),
    ])

  const stats = {
    dataSourcesCount: dataSourcesCountResult[0]?.count ?? 0,
    mcpToolsCount: mcpToolsCountResult[0]?.count ?? 0,
    updatedAt: lastUpdatedResult[0]?.updatedAt,
  }

  return (
    <div class="space-y-6">
      <H1Container>
        <h1 class="text-3xl font-bold">Dashboard</h1>
      </H1Container>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <StatCard.StatCard
          colorClass="text-primary"
          description="Registered search tools"
          title="MCP Tools"
          value={stats.mcpToolsCount}
        />
        <StatCard.StatCard
          colorClass="text-secondary"
          description="Configured data sources"
          title="Data Sources"
          value={stats.dataSourcesCount}
        />
        <StatCard.StatCard
          colorClass="text-info"
          description="System last updated"
          title="Updated"
          value={
            stats.updatedAt
              ? new Date(stats.updatedAt).toLocaleDateString("en-US")
              : "-"
          }
        />
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <ManagementCard.ManagementCard
          description="Add, edit, and delete search tools"
          href="/app/admin/mcp-tool"
          icon={Icon.ToolsIcon}
          iconLabel="MCP Tools Icon"
          title="MCP Tools Management"
        />
        <ManagementCard.ManagementCard
          description="Configure and manage data sources"
          href="/app/admin/data-source"
          icon={Icon.ServerIcon}
          iconLabel="Data Sources Icon"
          title="Data Sources Management"
        />
      </div>
    </div>
  )
}
