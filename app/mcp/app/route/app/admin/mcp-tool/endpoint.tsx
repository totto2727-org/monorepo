import { sValidator } from "@hono/standard-validator"
import { Effect, Option, Schema } from "@totto/function/effect"
import type { Database } from "#@/db.js"
import { factory } from "#@/hono.js"
import { mcpToolTable } from "#@/schema.js"
import { SimpleStatCard } from "#@/ui/admin/card/simple-stat-card.js"
import { Input } from "#@/ui/admin/input/input.js"
import { Textarea } from "#@/ui/admin/input/textarea.js"
import { createModal } from "#@/ui/admin/modal.js"
import { CheckIcon, PlusIcon } from "#@/ui/icons/icon.js"
import { formatDurationFromNow } from "#@/utils/duration.js"

const mcpToolSchema = Schema.Struct({
  description: Schema.NonEmptyString,
  lastUsed: Schema.Union(Schema.DateFromString, Schema.DateFromSelf),
  name: Schema.NonEmptyString,
  title: Schema.NonEmptyString,
})
const mcpToolWithoutLastUsedStandardSchema = Schema.standardSchemaV1(
  mcpToolSchema.omit("lastUsed"),
)

const mcpToolArraySchema = Schema.Array(mcpToolSchema)
const decodeArray = Schema.decodeSync(mcpToolArraySchema)

export const getHandler = factory.createHandlers(async (c) =>
  c.render(<GetComponent mcpToolArray={await retrieve(c.var.db)} />),
)

export const postHandler = factory.createHandlers(
  sValidator("form", mcpToolWithoutLastUsedStandardSchema),
  async (c) =>
    Effect.gen(function* () {
      const mcpTool = yield* Option.fromIterable(
        yield* Effect.tryPromise(() =>
          c.var.db.insert(mcpToolTable).values(c.req.valid("form")).returning(),
        ),
      )

      return c.render(<PostComponent {...mcpTool} />)
    }).pipe(Effect.runPromise),
)

async function retrieve(db: Database) {
  return decodeArray(
    await db.query.mcpToolTable.findMany({
      columns: {
        description: true,
        lastUsed: true,
        name: true,
        title: true,
      },
      orderBy(fields, operators) {
        return operators.desc(fields.createdAt)
      },
    }),
  )
}

function GetComponent(props: { mcpToolArray: typeof mcpToolArraySchema.Type }) {
  const AddNewMCPTool = createModal("add-new-mcp-tool-modal")

  const tableID = "mcp-tool-table"

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
          value={props.mcpToolArray.length}
        />
      </div>

      <div className="overflow-x-auto">
        <table className="table" id={tableID}>
          <thead>
            <tr>
              <th>Name</th>
              <th>Title</th>
              <th>Description</th>
              <th>Last used</th>
            </tr>
          </thead>
          <tbody>
            {props.mcpToolArray.map((tool) => (
              <TableItem {...tool} />
            ))}
          </tbody>
        </table>
      </div>

      <AddNewMCPTool.Modal>
        <div class="modal-box w-11/12 max-w-2xl">
          <h3 class="font-bold text-lg mb-4">Add New MCP Tool</h3>

          <AddNewMCPTool.Form
            class="space-y-4"
            hx-post="/app/admin/mcp-tool"
            hx-swap="afterbegin"
            hx-target={`#${tableID} > tbody`}
          >
            <Input
              description="Lowercase letters, numbers, and underscores only. Must start with a letter."
              inputAttributes={{
                id: "name",
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
                id: "title",
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
                id: "description",
                maxLength: 300,
                name: "description",
                placeholder:
                  "Describe the functionality and purpose of this MCP tool",
                required: true,
              }}
            />

            <div class="modal-action">
              <button class="btn btn-primary" type="submit">
                <CheckIcon ariaLabel="Save Icon" size="sm" />
                Add
              </button>
              <AddNewMCPTool.CloseButton class="btn btn-outline">
                Cancel
              </AddNewMCPTool.CloseButton>
            </div>
          </AddNewMCPTool.Form>
        </div>
      </AddNewMCPTool.Modal>
    </div>
  )
}

function PostComponent(props: typeof mcpToolSchema.Type) {
  return (
    <TableItem
      description={props.description}
      lastUsed={props.lastUsed}
      name={props.name}
      title={props.title}
    />
  )
}

function TableItem(props: typeof mcpToolSchema.Type) {
  return (
    <tr>
      <th>{props.name}</th>
      <td>{props.title}</td>
      <td>{props.description}</td>
      <td>{formatDurationFromNow(props.lastUsed)}</td>
    </tr>
  )
}
