import { desc } from "drizzle-orm"
import { createDatabase, schema } from "#@/db.js"
import { useRequestContext } from "#@/hono.js"
import type { DataSourceType } from "#@/sync/types.js"
import { SimpleStatCard } from "#@/ui/admin/card/simple-stat-card.js"
import { Input } from "#@/ui/admin/input/input.js"
import { Select } from "#@/ui/admin/input/select.js"
import { CheckIcon, DeleteIcon, PlusIcon } from "#@/ui/icons/icon.js"

const availableDataSourceTypes = [
  { label: "Text", value: "text" },
  { label: "Firecrawl", value: "firecrawl" },
] as const satisfies {
  label: string
  value: DataSourceType
}[]

function DataSourceItemForm(
  index: number,
  availableTypes: typeof availableDataSourceTypes,
) {
  return (
    <div class="border border-base-300 rounded-lg p-4 datasource-item">
      <div class="flex items-center justify-between mb-3">
        <span class="font-medium">Data Source #{index + 1}</span>
        <button
          class="btn btn-sm btn-ghost btn-circle"
          onclick="removeDataSource(this)"
          type="button"
        >
          <DeleteIcon ariaLabel="Delete" size="sm" />
        </button>
      </div>
      <div class="space-y-3">
        <Select
          name="Type"
          selectAttributes={{
            id: `datasource-${index}-type`,
            name: `datasources[${index}][type]`,
            required: true,
          }}
        >
          {availableTypes.map((type) => (
            <option value={type.value}>{type.label}</option>
          ))}
        </Select>
        <Input
          inputAttributes={{
            id: `datasource-${index}-url`,
            name: `datasources[${index}][url]`,
            placeholder: "https://example.com",
            required: true,
            type: "url",
          }}
          name="URL"
        ></Input>
      </div>
    </div>
  )
}

async function fetchDataSourcesAndTools() {
  const c = useRequestContext()
  const db = createDatabase(c.env.DB)
  return await db.batch([
    db
      .select({
        createdAt: schema.dataSource.createdAt,
        mcpToolName: schema.dataSource.mcpToolName,
        type: schema.dataSource.type,
        url: schema.dataSource.url,
      })
      .from(schema.dataSource)
      .orderBy(desc(schema.dataSource.createdAt)),
    db.select().from(schema.mcpTool).orderBy(schema.mcpTool.name),
  ])
}

export async function GetDataSources() {
  const [dataSources, mcpTools] = await fetchDataSourcesAndTools()
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

      <dialog class="modal" id="add-datasource-modal">
        <div class="modal-box w-11/12 max-w-2xl">
          <h3 class="font-bold text-lg mb-4">Add New Data Source</h3>

          <form
            class="space-y-4"
            hx-on="htmx:afterRequest: if(event.detail.successful) document.getElementById('add-datasource-modal').close()"
            hx-post="/app/admin/api/data-sources"
            hx-target="#datasources-table"
          >
            <Select
              name="MCP Tool"
              selectAttributes={{
                id: "datasource-mcptool",
                name: "mcpToolName",
                required: true,
              }}
            >
              {mcpTools.map((tool) => (
                <option value={tool.name}>{tool.title}</option>
              ))}
            </Select>

            <div class="form-control">
              <div class="label">
                <span class="label-text font-semibold">Data Sources</span>
                <span class="label-text-alt text-error">Required</span>
              </div>
              <div class="text-sm text-base-content/70 mb-2">
                At least 1 required
              </div>
              <div class="space-y-3" id="datasource-list">
                {DataSourceItemForm(0, availableTypes)}
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
  return null
}
