import { desc } from "drizzle-orm"
import type { Context } from "hono"
import { createDatabase, schema } from "#@/db.js"
import { CheckIcon, DeleteIcon, EditIcon, PlusIcon } from "#@/ui/icons/icon.js"

const availableDataSourceTypes = [
  { label: "Text", value: "text" as const },
  { label: "Firecrawl", value: "firecrawl" as const },
]

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
  const [rawDataSources, mcpTools] = await db.batch([
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

  // Group data sources by mcp tool name
  const groupedDataSources = rawDataSources.reduce(
    (acc, source) => {
      const toolName = source.mcpToolName
      if (!acc[toolName]) {
        acc[toolName] = {
          createdAt: source.createdAt,
          id: `ds_${toolName}`,
          mcpToolName: toolName,
          sources: [],
          updatedAt: source.createdAt,
        }
      }
      acc[toolName].sources.push({
        type: source.type,
        url: source.url,
      })
      return acc
    },
    {} as Record<
      string,
      {
        id: string
        mcpToolName: string
        sources: Array<{ url: string; type: string }>
        createdAt: string
        updatedAt: string
      }
    >,
  )

  const dataSources = Object.values(groupedDataSources)

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
                {dataSources.map((ds) => (
                  <tr key={ds.id}>
                    <td>
                      <div class="font-mono text-sm">{ds.id}</div>
                    </td>
                    <td>
                      <div class="badge badge-outline">{ds.mcpToolName}</div>
                    </td>
                    <td>
                      <div class="space-y-1">
                        {ds.sources.map((source, index) => (
                          <div
                            class="flex items-center gap-2"
                            key={`${ds.id}-source-${index}`}
                          >
                            <div class="badge badge-sm">{source.type}</div>
                            <div class="text-sm text-base-content/70 truncate max-w-xs">
                              {source.url}
                            </div>
                          </div>
                        ))}
                      </div>
                    </td>
                    <td>
                      <div class="text-sm">
                        {(() => {
                          const now = new Date()
                          const updatedAt = new Date(ds.updatedAt)
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
                          onclick={`editDataSource('${ds.id}')`}
                          type="button"
                        >
                          <EditIcon ariaLabel="Edit Icon" size="sm" />
                        </button>
                        <button
                          class="btn btn-sm btn-error btn-outline"
                          onclick={`deleteDataSource('${ds.id}')`}
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

      <script>
        {`
          let dataSourceIndex = 1;

          function addDataSourceField() {
            const container = document.getElementById('datasource-list');
            const newItem = document.createElement('div');
            newItem.className = 'border border-base-300 rounded-lg p-4 datasource-item';
            newItem.innerHTML = \`
              <div class="flex items-center justify-between mb-3">
                <span class="font-medium">Data Source #\${dataSourceIndex + 1}</span>
                <button class="btn btn-sm btn-ghost btn-circle" onclick="removeDataSource(this)" type="button">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" role="img" aria-label="Delete">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                  </svg>
                </button>
              </div>
              <div class="space-y-3">
                <div class="form-control">
                  <div class="label">
                    <span class="label-text">Type</span>
                    <span class="label-text-alt text-error">Required</span>
                  </div>
                  <select class="select select-bordered select-sm" name="datasources[\${dataSourceIndex}][type]" required>
                    <option value="">Select</option>
                    <option value="text">Text</option>
                    <option value="firecrawl">Firecrawl</option>
                  </select>
                </div>
                <div class="form-control">
                  <div class="label">
                    <span class="label-text">URL</span>
                    <span class="label-text-alt text-error">Required</span>
                  </div>
                  <input class="input input-bordered input-sm" name="datasources[\${dataSourceIndex}][url]" placeholder="https://example.com" required type="url" />
                </div>
              </div>
            \`;
            container.appendChild(newItem);
            dataSourceIndex++;
          }

          function removeDataSource(button) {
            const item = button.closest('.datasource-item');
            const container = document.getElementById('datasource-list');
            if (container.children.length > 1) {
              item.remove();
            } else {
              alert('At least one data source is required.');
            }
          }

          function editDataSource(dataSourceId) {
            htmx.ajax('GET', '/app/admin/api/data-sources/' + dataSourceId + '/edit', {
              target: '#edit-datasource-content',
              swap: 'innerHTML'
            }).then(() => {
              document.getElementById('edit-datasource-modal').showModal();
            });
          }

          function deleteDataSource(dataSourceId) {
            if (confirm('Are you sure you want to delete this data source? This action cannot be undone.')) {
              htmx.ajax('DELETE', '/app/admin/api/data-sources/' + dataSourceId, {
                target: '#datasources-table',
                swap: 'outerHTML'
              });
            }
          }
        `}
      </script>

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
