import { desc } from "drizzle-orm"
import { createDatabase, schema } from "#@/db.js"
import { useRequestContext } from "#@/hono.js"
import type { DataSourceType } from "#@/sync/types.js"
import { SimpleStatCard } from "#@/ui/admin/card/simple-stat-card.js"
import { Input } from "#@/ui/admin/input/input.js"
import { Select } from "#@/ui/admin/input/select.js"
import { createModal } from "#@/ui/admin/modal.js"
import { CheckIcon, DeleteIcon, PlusIcon } from "#@/ui/icons/icon.js"
import { formatDurationFromNow } from "#@/utils/duration.js"

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

function TableItem(props: {
  mcpToolName: string
  type: string
  url: string
  createdAt: Date
}) {
  return (
    <tr>
      <th>{props.mcpToolName}</th>
      <td>{props.type}</td>
      <td>{props.url}</td>
      <td>{formatDurationFromNow(props.createdAt)}</td>
    </tr>
  )
}

async function fetchDataSourcesAndTools() {
  const c = useRequestContext()
  const db = createDatabase(c.env.DB)
  return await db.batch([
    db
      .select({
        createdAt: schema.dataSourceTable.createdAt,
        mcpToolName: schema.dataSourceTable.mcpToolName,
        type: schema.dataSourceTable.type,
        url: schema.dataSourceTable.url,
      })
      .from(schema.dataSourceTable)
      .orderBy(desc(schema.dataSourceTable.createdAt)),
    db.select().from(schema.mcpToolTable).orderBy(schema.mcpToolTable.name),
  ])
}

export async function GetDataSource() {
  const [dataSources, mcpTools] = await fetchDataSourcesAndTools()
  const availableTypes = availableDataSourceTypes

  const AddNewDataSourceModal = createModal("add-new-data-source-modal")

  const tableID = "mcp-tool-table"

  return (
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">Data Sources Management</h1>
        <AddNewDataSourceModal.OpenButton class="btn btn-primary">
          <PlusIcon ariaLabel="Add Icon" size="sm" />
          Add New Data Source
        </AddNewDataSourceModal.OpenButton>
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

      <div className="overflow-x-auto">
        <table className="table" id={tableID}>
          <thead>
            <tr>
              <th>Tool name</th>
              <th>Type</th>
              <th>URL</th>
              <th>Created At</th>
            </tr>
          </thead>
          <tbody>
            {dataSources.map((tool) => (
              <TableItem {...tool} />
            ))}
          </tbody>
        </table>
      </div>

      <AddNewDataSourceModal.Modal>
        <div class="modal-box w-11/12 max-w-2xl">
          <h3 class="font-bold text-lg mb-4">Add New Data Source</h3>

          <AddNewDataSourceModal.Form
            class="space-y-4"
            hx-post="/app/admin/data-source"
            hx-swap="afterbegin"
            hx-target={`#${tableID} > tbody`}
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
              <AddNewDataSourceModal.CloseButton class="btn btn-outline">
                Cancel
              </AddNewDataSourceModal.CloseButton>
            </div>
          </AddNewDataSourceModal.Form>
        </div>
      </AddNewDataSourceModal.Modal>
    </div>
  )
}

export const PostDataSource = async () => {
  // TODO
  return <TableItem createdAt={new Date()} mcpToolName="a" type="a" url="a" />
}
