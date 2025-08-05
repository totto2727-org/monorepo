import { dashboardStats } from "../data/mock-data.js"
import { ServerIcon, ToolsIcon } from "../ui/icons/icon.js"

export function Dashboard() {
  const stats = dashboardStats

  return (
    <div class="space-y-6">
      {/* Page Header */}
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">Admin Dashboard</h1>
      </div>

      {/* Statistics Cards */}
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title text-primary">MCP Tools</h2>
            <p class="text-2xl font-bold">{stats.mcpToolsCount}</p>
            <p class="text-sm text-base-content/70">Registered search tools</p>
          </div>
        </div>

        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title text-secondary">Data Sources</h2>
            <p class="text-2xl font-bold">{stats.dataSourcesCount}</p>
            <p class="text-sm text-base-content/70">Configured data sources</p>
          </div>
        </div>

        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title text-info">Updated</h2>
            <p class="text-sm">
              {new Date(stats.updatedAt).toLocaleDateString("en-US")}
            </p>
            <p class="text-sm text-base-content/70">System last updated</p>
          </div>
        </div>
      </div>

      {/* Management Menu */}
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* MCP Tools Management */}
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title flex items-center gap-2">
              <ToolsIcon ariaLabel="MCP Tools Icon" size="md" />
              MCP Tools Management
            </h2>
            <p class="text-base-content/70">
              Add, edit, and delete search tools
            </p>
            <div class="card-actions justify-end mt-4">
              <a class="btn btn-primary" href="/app/admin/mcp-tools">
                Manage
              </a>
            </div>
          </div>
        </div>

        {/* Data Sources Management */}
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title flex items-center gap-2">
              <ServerIcon ariaLabel="Data Sources Icon" size="md" />
              Data Sources Management
            </h2>
            <p class="text-base-content/70">
              Configure and manage data sources
            </p>
            <div class="card-actions justify-end mt-4">
              <a class="btn btn-primary" href="/app/admin/data-sources">
                Manage
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
