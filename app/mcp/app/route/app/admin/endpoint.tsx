import { Body } from "@package/hono-ui/app-shell"
import * as Icon from "@package/hono-ui/icon"
import { count, sql } from "drizzle-orm"
import * as Table from "#@/feature/database/drizzle.js"
import * as DataBase from "#@/feature/database.js"
import * as Hono from "#@/feature/hono.js"
import * as ManagementCard from "#@/feature/ui/admin/card/management-card.js"
import * as StatCard from "#@/feature/ui/admin/card/stat-card.js"

export async function Dashboard() {
  const c = Hono.useRequestContext()
  const db = DataBase.create(c.env.DB)
  const [mcpToolsCountResult, dataSourcesCountResult, lastUpdatedResult] =
    await db.batch([
      db.select({ count: count() }).from(Table.mcpToolTable),
      db.select({ count: count() }).from(Table.dataSourceTable),
      db
        .select({
          updatedAt: sql<string>`MAX(${Table.mcpToolTable.lastUsed})`.as(
            "updatedAt",
          ),
        })
        .from(Table.mcpToolTable),
    ])

  const statsRecord = {
    dataSourcesCount: dataSourcesCountResult[0]?.count ?? 0,
    mcpToolsCount: mcpToolsCountResult[0]?.count ?? 0,
    updatedAt: lastUpdatedResult[0]?.updatedAt,
  }

  return (
    <Body title="Dashboard">
      <div class="grid grid-cols-1 gap-6 md:grid-cols-3">
        <StatCard.StatCard
          colorClass="text-primary"
          description="Registered search tools"
          title="MCP Tools"
          value={statsRecord.mcpToolsCount}
        />
        <StatCard.StatCard
          colorClass="text-secondary"
          description="Configured data sources"
          title="Data Sources"
          value={statsRecord.dataSourcesCount}
        />
        <StatCard.StatCard
          colorClass="text-info"
          description="System last updated"
          title="Updated"
          value={
            statsRecord.updatedAt
              ? new Date(statsRecord.updatedAt).toLocaleDateString("en-US")
              : "-"
          }
        />
      </div>

      <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <ManagementCard.ManagementCard
          description="Add, edit, and delete search tools"
          href="/app/admin/mcp-tool"
          icon={Icon.Tools}
          iconLabel="MCP Tools"
          title="MCP Tools Management"
        />
        <ManagementCard.ManagementCard
          description="Configure and manage data sources"
          href="/app/admin/data-source"
          icon={Icon.Server}
          iconLabel="Data Sources"
          title="Data Sources Management"
        />
      </div>
    </Body>
  )
}
