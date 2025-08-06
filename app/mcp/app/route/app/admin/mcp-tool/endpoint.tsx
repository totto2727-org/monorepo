import { desc } from "drizzle-orm"
import { createDatabase, schema } from "#@/db.js"
import { useRequestContext } from "#@/hono.js"
import { SimpleStatCard } from "#@/ui/admin/card/simple-stat-card.js"
import { createModal } from "#@/ui/admin/dialog.js"
import { Input } from "#@/ui/admin/input/input.js"
import { Textarea } from "#@/ui/admin/input/textarea.js"
import { CheckIcon, PlusIcon } from "#@/ui/icons/icon.js"

async function fetchMcpTools() {
  const c = useRequestContext()
  const db = createDatabase(c.env.DB)
  return await db
    .select()
    .from(schema.mcpTool)
    .orderBy(desc(schema.mcpTool.createdAt))
}

export const GetMcpTool = async () => {
  const tools = await fetchMcpTools()
  const AddNewMCPTool = createModal("add-new-mcp-tool-modal")

  return (
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">MCP Tools Management</h1>
        <AddNewMCPTool.OpenButton class="btn btn-primary">
          <PlusIcon ariaLabel="Add Icon" size="sm" />
          Add New MCP Tool
        </AddNewMCPTool.OpenButton>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <SimpleStatCard
          colorClass="text-primary"
          title="Total MCP Tools"
          value={tools.length}
        />
      </div>

      <AddNewMCPTool.Modal>
        <div class="modal-box w-11/12 max-w-2xl">
          <h3 class="font-bold text-lg mb-4">Add New MCP Tool</h3>

          <form
            class="space-y-4"
            hx-on="htmx:afterRequest: if(event.detail.successful) document.getElementById('add-tool-modal').close()"
            hx-post="/app/admin/api/mcp-tools"
            hx-target="#tools-table"
          >
            <Input
              description="Lowercase letters, numbers, and underscores only. Must start with a letter."
              inputAttributes={{
                id: "tool-name",
                name: "name",
                pattern: "^[a-z][a-z0-9_]*$",
                placeholder: "example",
                required: true,
                type: "text",
              }}
              name="Name"
            />
            <Input
              inputAttributes={{
                id: "tool-title",
                maxLength: 100,
                name: "title",
                placeholder: "Example Documentation Search",
                required: true,
                type: "text",
              }}
              name="Title"
            />

            <Textarea
              name="Description"
              textareaAttributes={{
                class: "textarea textarea-bordered h-24",
                id: "tool-description",
                maxLength: 300,
                name: "description",
                placeholder:
                  "Describe the functionality and purpose of this MCP tool",
                required: true,
              }}
            />

            <div class="modal-action">
              <AddNewMCPTool.CloseButton class="btn btn-primary" type="submit">
                <CheckIcon ariaLabel="Save Icon" size="sm" />
                Add
              </AddNewMCPTool.CloseButton>
              <AddNewMCPTool.CloseButton class="btn btn-outline">
                Cancel
              </AddNewMCPTool.CloseButton>
            </div>
          </form>
        </div>
      </AddNewMCPTool.Modal>
    </div>
  )
}

export const PostMcpTool = async () => {
  return <div></div>
}
