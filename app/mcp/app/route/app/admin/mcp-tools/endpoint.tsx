import { desc } from "drizzle-orm"
import type { Context } from "hono"
import { createDatabase, schema } from "#@/db.js"
import { SimpleStatCard } from "#@/ui/admin/card/simple-stat-card.js"
import { CheckIcon, DeleteIcon, EditIcon, PlusIcon } from "#@/ui/icons/icon.js"
import { formatDurationFromNow } from "#@/utils/duration.js"

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
        <SimpleStatCard
          colorClass="text-primary"
          title="Total MCP Tools"
          value={tools.length}
        />
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
                        {formatDurationFromNow(new Date(tool.lastUsed))}
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
              <div class="label">
                <span class="label-text font-semibold">Name</span>
                <span class="label-text-alt text-error">Required</span>
              </div>
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
              <div class="label">
                <span class="label-text font-semibold">Title</span>
                <span class="label-text-alt text-error">Required</span>
              </div>
              <div>
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
            </div>

            <div class="form-control">
              <div class="label">
                <span class="label-text font-semibold">Description</span>
                <span class="label-text-alt text-error">Required</span>
              </div>
              <div>
                <textarea
                  class="textarea textarea-bordered h-24"
                  id="tool-description"
                  maxLength={300}
                  name="description"
                  placeholder="Describe the functionality and purpose of this MCP tool"
                  required
                ></textarea>
              </div>
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
