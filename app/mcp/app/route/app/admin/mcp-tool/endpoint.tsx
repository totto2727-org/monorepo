import { sValidator } from "@hono/standard-validator"
import * as Duration from "@totto/function/duration"
import { DateTime, Effect, Option, Schema } from "@totto/function/effect"
import { eq } from "drizzle-orm"
import * as Icon from "hono-ui/icon"
import * as Drizzle from "#@/feature/database/drizzle.js"
import type { Database } from "#@/feature/database.js"
import * as Hono from "#@/feature/hono.js"
import { getDefaultLocale } from "#@/feature/locale.js"
import * as SimpleStatCard from "#@/feature/ui/admin/card/simple-stat-card.js"
import { H1Container } from "#@/feature/ui/admin/h1-container.js"
import * as Input from "#@/feature/ui/admin/input/input.js"
import * as Textarea from "#@/feature/ui/admin/input/textarea.js"
import * as Modal from "#@/feature/ui/admin/modal.js"

const mcpToolSchema = Schema.Struct({
  description: Schema.NonEmptyString,
  lastUsed: Schema.Union(Schema.DateFromString, Schema.DateFromSelf),
  name: Schema.NonEmptyString,
  title: Schema.NonEmptyString,
})
const mcpToolWithoutLastUsedStandardSchema = Schema.standardSchemaV1(
  mcpToolSchema.omit("lastUsed"),
)

const deleteQuerySchema = Schema.Struct({
  name: Schema.NonEmptyString,
})
const deleteQueryStandardSchema = Schema.standardSchemaV1(deleteQuerySchema)
const encodeDeleteQuery = Schema.encodeSync(deleteQuerySchema)

const mcpToolArraySchema = Schema.Array(mcpToolSchema)
const decodeArray = Schema.decodeSync(mcpToolArraySchema)

export const getHandler = Hono.factory.createHandlers(async (c) =>
  c.render(<GetComponent mcpToolArray={await retrieve(c.var.db)} />),
)

export const postHandler = Hono.factory.createHandlers(
  sValidator("form", mcpToolWithoutLastUsedStandardSchema),
  async (c) =>
    Effect.gen(function* () {
      const mcpTool = yield* Option.fromIterable(
        yield* Effect.tryPromise(() =>
          c.var.db
            .insert(Drizzle.mcpToolTable)
            .values(c.req.valid("form"))
            .returning(),
        ),
      )

      return c.render(<PostComponent {...mcpTool} />)
    }).pipe(Effect.runPromise),
)

export const deleteHandler = Hono.factory.createHandlers(
  sValidator("query", deleteQueryStandardSchema),
  async (c) =>
    Effect.gen(function* () {
      const query = c.req.valid("query")

      yield* Effect.tryPromise(() =>
        c.var.db
          .delete(Drizzle.mcpToolTable)
          .where(eq(Drizzle.mcpToolTable.name, query.name)),
      )

      return c.json(null)
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
  const AddNewMCPTool = Modal.createModal("add-new-mcp-tool-modal")

  const tableID = "mcp-tool-table"

  return (
    <div class="space-y-6">
      <H1Container>
        <h1 class="text-3xl font-bold">MCP Tools</h1>
        <AddNewMCPTool.OpenButton class="btn btn-primary">
          <Icon.Plus ariaLabel="Add" size="sm" />
          Add New MCP Tool
        </AddNewMCPTool.OpenButton>
      </H1Container>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <SimpleStatCard.SimpleStatCard
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
              <th>Actions</th>
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
            <Input.Input
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
            <Input.Input
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

            <Textarea.Textarea
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
                <Icon.Check ariaLabel="Save" size="sm" />
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
      <td>
        {Duration.formatShort(
          DateTime.unsafeFromDate(props.lastUsed),
          DateTime.unsafeNow(),
          {
            locale: getDefaultLocale(),
          },
        )}
      </td>
      <td>
        <button
          class="btn btn-error btn-sm"
          hx-delete={`/app/admin/mcp-tool?${new URLSearchParams(
            encodeDeleteQuery({
              name: props.name,
            }),
          ).toString()}`}
          hx-swap="delete"
          hx-target="closest tr"
          type="button"
        >
          <Icon.Delete ariaLabel="Delete" size="sm" />
        </button>
      </td>
    </tr>
  )
}
