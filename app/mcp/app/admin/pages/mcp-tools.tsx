import { desc } from "drizzle-orm"
import type { Context } from "hono"
import { createDatabase, schema } from "#@/db/db.js"
import { CheckIcon, DeleteIcon, EditIcon, PlusIcon } from "../ui/icons/icon.js"

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

export async function McpToolsManager(c: Context) {
  const db = createDatabase(c.env.DB)
  const tools = await db
    .select()
    .from(schema.mcpTool)
    .orderBy(desc(schema.mcpTool.createdAt))

  return (
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">MCP Tools Management</h1>
        <button
          class="btn btn-primary"
          onclick="document.getElementById('add-tool-modal').showModal()"
          type="button"
        >
          <PlusIcon ariaLabel="Add Icon" size="sm" />
          Add New MCP Tool
        </button>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <StatCard
          colorClass="text-primary"
          title="Total MCP Tools"
          value={tools.length}
        />
      </div>

      <div class="card bg-base-100 shadow-lg">
        <div class="card-body">
          <div class="flex flex-col md:flex-row gap-4">
            <div class="form-control flex-1">
              <input
                class="input input-bordered"
                hx-get="/app/admin/api/mcp-tools/search"
                hx-target="#tools-table"
                hx-trigger="keyup changed delay:300ms"
                id="tool-search"
                name="search"
                placeholder="Search MCP tools..."
                type="text"
              />
            </div>
          </div>
        </div>
      </div>

      <div class="card bg-base-100 shadow-lg">
        <div class="card-body">
          <div class="overflow-x-auto" id="tools-table">
            <table class="table table-zebra">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Title</th>
                  <th>Used</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {tools.map((tool) => (
                  <tr key={tool.name}>
                    <td>
                      <div class="font-mono text-sm">{tool.name}</div>
                    </td>
                    <td>
                      <div>
                        <div class="font-semibold">{tool.title}</div>
                        <div class="text-sm text-base-content/70 truncate max-w-xs">
                          {tool.description}
                        </div>
                      </div>
                    </td>
                    <td>
                      <div class="text-sm">
                        {(() => {
                          const now = new Date()
                          const lastUsed = new Date(tool.lastUsed)
                          const diffMs = now.getTime() - lastUsed.getTime()
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
                          onclick={`editTool('${tool.name}')`}
                          type="button"
                        >
                          <EditIcon ariaLabel="Edit Icon" size="sm" />
                        </button>
                        <button
                          class="btn btn-sm btn-error btn-outline"
                          onclick={`deleteTool('${tool.name}')`}
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

      <dialog class="modal" id="add-tool-modal">
        <div class="modal-box w-11/12 max-w-2xl">
          <h3 class="font-bold text-lg mb-4">Add New MCP Tool</h3>

          <form
            class="space-y-4"
            hx-on="htmx:afterRequest: if(event.detail.successful) document.getElementById('add-tool-modal').close()"
            hx-post="/app/admin/api/mcp-tools"
            hx-target="#tools-table"
          >
            <div class="form-control">
              <label class="label" htmlFor="tool-name">
                <span class="label-text font-semibold">
                  Tool Name <span class="text-error">*</span>
                </span>
              </label>
              <div class="text-sm text-base-content/70 mb-2">
                Lowercase letters, numbers, and underscores only. Must start
                with a letter
              </div>
              <input
                class="input input-bordered"
                id="tool-name"
                name="name"
                pattern="^[a-z][a-z0-9_]*$"
                placeholder="example"
                required
                type="text"
              />
            </div>

            <div class="form-control">
              <label class="label" htmlFor="tool-title">
                <span class="label-text font-semibold">
                  Title <span class="text-error">*</span>
                </span>
              </label>
              <input
                class="input input-bordered"
                id="tool-title"
                maxLength={100}
                name="title"
                placeholder="Example Documentation Search"
                required
                type="text"
              />
            </div>

            <div class="form-control">
              <label class="label" htmlFor="tool-description">
                <span class="label-text font-semibold">
                  Description <span class="text-error">*</span>
                </span>
              </label>
              <textarea
                class="textarea textarea-bordered h-24"
                id="tool-description"
                maxLength={300}
                name="description"
                placeholder="Describe the functionality and purpose of this MCP tool"
                required
              ></textarea>
            </div>

            <div class="modal-action">
              <button class="btn btn-primary" type="submit">
                <CheckIcon ariaLabel="Save Icon" size="sm" />
                Add
              </button>
              <button
                class="btn btn-outline"
                onclick="document.getElementById('add-tool-modal').close()"
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
          function editTool(toolId) {
            htmx.ajax('GET', '/app/admin/api/mcp-tools/' + toolId + '/edit', {
              target: '#edit-tool-content',
              swap: 'innerHTML'
            }).then(() => {
              document.getElementById('edit-tool-modal').showModal();
            });
          }

          function deleteTool(toolId) {
            if (confirm('Are you sure you want to delete this MCP tool? This action cannot be undone.')) {
              htmx.ajax('DELETE', '/app/admin/api/mcp-tools/' + toolId, {
                target: '#tools-table',
                swap: 'outerHTML'
              });
            }
          }
        `}
      </script>

      <dialog class="modal" id="edit-tool-modal">
        <div class="modal-box w-11/12 max-w-2xl">
          <div id="edit-tool-content"></div>
        </div>
        <form class="modal-backdrop" method="dialog">
          <button type="button">close</button>
        </form>
      </dialog>
    </div>
  )
}
