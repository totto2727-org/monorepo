import { desc } from "drizzle-orm"
import type { Context } from "hono"
import { createDatabase, schema } from "#@/db.js"
import { CheckIcon, DeleteIcon, EditIcon, PlusIcon } from "#@/ui/icons/icon.js"

const availableDataSourceTypes = [
  { label: "Text", value: "text" },
  { label: "Firecrawl", value: "firecrawl" },
] as const

type StatCardProps = {
  title: string
  value: string | number
  colorClass?: string
}

function StatCard({
  title,
  value,
  colorClass = "text-primary",
}: StatCardProps) {
  return (
    <div class="stat bg-base-100 rounded-lg shadow">
      <div class="stat-title">{title}</div>
      <div class={`stat-value ${colorClass}`}>{value}</div>
    </div>
  )
}

export async function DataSourcesManager(c: Context) {
  const db = createDatabase(c.env.DB)
  const [dataSources, mcpTools] = await db.batch([
    db
      .select({
        createdAt: schema.dataSource.createdAt,
        mcpToolName: schema.dataSource.mcpToolName,
        type: schema.dataSource.type,
        url: schema.dataSource.url,
      })
      .from(schema.dataSource)
      .orderBy(
        schema.dataSource.mcpToolName,
        desc(schema.dataSource.createdAt),
      ),
    db.select().from(schema.mcpTool).orderBy(schema.mcpTool.name),
  ])
  const availableTypes = availableDataSourceTypes

  return (
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">Data Sources Management</h1>
        <button
          class="btn btn-primary"
          onclick="document.getElementById('add-datasource-modal').showModal()"
          type="button"
        >
          <PlusIcon ariaLabel="Add Icon" size="sm" />
          Add New Data Source
        </button>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <StatCard
          colorClass="text-primary"
          title="Total Data Sources"
          value={dataSources.length}
        />
        <StatCard
          colorClass="text-info"
          title="MCP Tools"
          value={mcpTools.length}
        />
      </div>

      <div class="card bg-base-100 shadow-lg">
        <div class="card-body">
          <div class="overflow-x-auto" id="datasources-table">
            <table class="table table-zebra">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>MCP Tool</th>
                  <th>Sources</th>
                  <th>Updated</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {dataSources.map((dataSource) => (
                  <tr key={dataSource.mcpToolName}>
                    <td>
                      <div class="font-mono text-sm">
                        {dataSource.mcpToolName}
                      </div>
                    </td>
                    <td>
                      <div class="badge badge-outline">
                        {dataSource.mcpToolName}
                      </div>
                    </td>
                    <td>
                      <div class="flex items-center gap-2">
                        <div class="badge badge-sm">{dataSource.type}</div>
                        <div class="text-sm text-base-content/70 truncate max-w-xs">
                          {dataSource.url}
                        </div>
                      </div>
                    </td>
                    <td>
                      <div class="text-sm">
                        {(() => {
                          const now = new Date()
                          const updatedAt = new Date(dataSource.createdAt)
                          const diffMs = now.getTime() - updatedAt.getTime()
                          const diffDays = Math.floor(
                            diffMs / (1000 * 60 * 60 * 24),
                          )
                          const diffHours = Math.floor(
                            diffMs / (1000 * 60 * 60),
                          )
                          const diffMinutes = Math.floor(diffMs / (1000 * 60))

                          if (diffDays > 0) return `${diffDays}d ago`
                          if (diffHours > 0) return `${diffHours}h ago`
                          if (diffMinutes > 0) return `${diffMinutes}m ago`
                          return "Just now"
                        })()}
                      </div>
                    </td>
                    <td>
                      <div class="flex gap-2">
                        <button
                          class="btn btn-sm btn-outline"
                          onclick={`editDataSource('${dataSource.mcpToolName}')`}
                          type="button"
                        >
                          <EditIcon ariaLabel="Edit Icon" size="sm" />
                        </button>
                        <button
                          class="btn btn-sm btn-error btn-outline"
                          onclick={`deleteDataSource('${dataSource.mcpToolName}')`}
                          type="button"
                        >
                          <DeleteIcon ariaLabel="Delete Icon" size="sm" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <dialog class="modal" id="add-datasource-modal">
        <div class="modal-box w-11/12 max-w-2xl">
          <h3 class="font-bold text-lg mb-4">Add New Data Source</h3>

          <form
            class="space-y-4"
            hx-on="htmx:afterRequest: if(event.detail.successful) document.getElementById('add-datasource-modal').close()"
            hx-post="/app/admin/api/data-sources"
            hx-target="#datasources-table"
          >
            <div class="form-control">
              <div class="label">
                <span class="label-text font-semibold">MCP Tool</span>
                <span class="label-text-alt text-error">Required</span>
              </div>
              <div>
                <select
                  class="select select-bordered"
                  id="datasource-mcptool"
                  name="mcpToolName"
                  required
                >
                  <option value="">Select MCP Tool</option>
                  {mcpTools.map((tool) => (
                    <option key={tool.name} value={tool.name}>
                      {tool.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div class="form-control">
              <div class="label">
                <span class="label-text font-semibold">Data Sources</span>
                <span class="label-text-alt text-error">Required</span>
              </div>
              <div class="text-sm text-base-content/70 mb-2">
                At least 1 required
              </div>
              <div class="space-y-3" id="datasource-list">
                <div class="border border-base-300 rounded-lg p-4 datasource-item">
                  <div class="flex items-center justify-between mb-3">
                    <span class="font-medium">Data Source #1</span>
                    <button
                      class="btn btn-sm btn-ghost btn-circle"
                      onclick="removeDataSource(this)"
                      type="button"
                    >
                      <DeleteIcon ariaLabel="Delete" size="sm" />
                    </button>
                  </div>
                  <div class="space-y-3">
                    <div class="form-control">
                      <div class="label">
                        <span class="label-text">Type</span>
                        <span class="label-text-alt text-error">Required</span>
                      </div>
                      <div>
                        <select
                          class="select select-bordered select-sm"
                          id="datasource-0-type"
                          name="datasources[0][type]"
                          required
                        >
                          <option value="">Select</option>
                          {availableTypes.map((type) => (
                            <option key={type.value} value={type.value}>
                              {type.label}
                            </option>
                          ))}
                        </select>
                      </div>
                    </div>
                    <div class="form-control">
                      <div class="label">
                        <span class="label-text">URL</span>
                        <span class="label-text-alt text-error">Required</span>
                      </div>
                      <div>
                        <input
                          class="input input-bordered input-sm"
                          id="datasource-0-url"
                          name="datasources[0][url]"
                          placeholder="https://example.com"
                          required
                          type="url"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <button
                class="btn btn-sm btn-outline mt-3"
                onclick="addDataSourceField()"
                type="button"
              >
                <PlusIcon ariaLabel="Add" size="sm" />
                Add Data Source
              </button>
            </div>

            <div class="modal-action">
              <button class="btn btn-primary" type="submit">
                <CheckIcon ariaLabel="Save Icon" size="sm" />
                Add
              </button>
              <button
                class="btn btn-outline"
                onclick="document.getElementById('add-datasource-modal').close()"
                type="button"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
        <form class="modal-backdrop" method="dialog">
          <button type="button">close</button>
        </form>
      </dialog>

      <dialog class="modal" id="edit-datasource-modal">
        <div class="modal-box w-11/12 max-w-2xl">
          <div id="edit-datasource-content"></div>
        </div>
        <form class="modal-backdrop" method="dialog">
          <button type="button">close</button>
        </form>
      </dialog>
    </div>
  )
}
