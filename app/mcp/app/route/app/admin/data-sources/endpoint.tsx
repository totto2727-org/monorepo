import { desc, sql } from "drizzle-orm"
import { createDatabase, schema } from "#@/db.js"
import { useRequestContext } from "#@/hono.js"
import { SimpleStatCard } from "#@/ui/admin/card/simple-stat-card.js"
import { CheckIcon, DeleteIcon, EditIcon, PlusIcon } from "#@/ui/icons/icon.js"
import { formatDurationFromNow } from "#@/utils/duration.js"

const availableDataSourceTypes = [
  { label: "Text", value: "text" },
  { label: "Firecrawl", value: "firecrawl" },
] as const

export async function GetDataSources() {
  const c = useRequestContext()
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
        <SimpleStatCard
          colorClass="text-primary"
          title="Total Data Sources"
          value={dataSources.length}
        />
        <SimpleStatCard
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
                        {formatDurationFromNow(new Date(dataSource.createdAt))}
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

export async function PostDataSources() {
  const c = useRequestContext()
  const db = createDatabase(c.env.DB)
  const body = await c.req.parseBody()

  const mcpToolName = body.mcpToolName as string
  const newDataSources = []

  let index = 0
  while (body[`datasources[${index}][type]`]) {
    const type = body[`datasources[${index}][type]`] as string
    if (type === "text" || type === "firecrawl") {
      newDataSources.push({
        mcpToolName,
        type: type as "text" | "firecrawl",
        url: body[`datasources[${index}][url]`] as string,
      })
    }
    index++
  }

  for (const dataSource of newDataSources) {
    await db.insert(schema.dataSource).values(dataSource)
  }

  const rawDataSources = await db
    .select({
      createdAt: schema.dataSource.createdAt,
      mcpToolName: schema.dataSource.mcpToolName,
      type: schema.dataSource.type,
      url: schema.dataSource.url,
    })
    .from(schema.dataSource)
    .orderBy(schema.dataSource.mcpToolName, sql`created_at DESC`)

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
    {} as Record<string, any>,
  )

  const finalDataSources = Object.values(groupedDataSources)

  return (
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
          {finalDataSources.map((ds: any) => (
            <tr key={ds.id}>
              <td>
                <div class="font-mono text-sm">{ds.id}</div>
              </td>
              <td>
                <div class="badge badge-outline">{ds.mcpToolName}</div>
              </td>
              <td>
                <div class="space-y-1">
                  {ds.sources.map((source: any, index: number) => (
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
                <div class="text-sm">{formatDurationFromNow(ds.updatedAt)}</div>
              </td>
              <td>
                <div class="flex gap-2">
                  <button class="btn btn-sm btn-outline" type="button">
                    Edit
                  </button>
                  <button
                    class="btn btn-sm btn-error btn-outline"
                    type="button"
                  >
                    Delete
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
