import { sValidator } from "@hono/standard-validator"
import * as Duration from "@totto/function/duration"
import { DateTime, Effect, Option, Schema } from "@totto/function/effect"
import { and, eq } from "drizzle-orm"
import * as Drizzle from "#@/feature/database/drizzle.js"
import type { Database } from "#@/feature/database.js"
import * as Hono from "#@/feature/hono.js"
import { getDefaultLocale } from "#@/feature/locale.js"
import type * as DataSourceType from "#@/feature/sync/type/data-source-type.js"
import * as SimpleStatCard from "#@/feature/ui/admin/card/simple-stat-card.js"
import { H1Container } from "#@/feature/ui/admin/h1-container.js"
import * as Input from "#@/feature/ui/admin/input/input.js"
import * as Select from "#@/feature/ui/admin/input/select.js"
import * as Modal from "#@/feature/ui/admin/modal.js"
import * as Icon from "#@/feature/ui/icons/icon.js"

const availableDataSourceTypes = [
  { label: "Text", value: "text" },
  { label: "Firecrawl", value: "firecrawl" },
] as const satisfies {
  label: string
  value: typeof DataSourceType.schema.Type
}[]

const dataSourceSchema = Schema.Struct({
  createdAt: Schema.Union(Schema.DateFromSelf, Schema.DateFromString),
  mcpToolName: Schema.NonEmptyString,
  type: Schema.Literal("text", "firecrawl"),
  url: Schema.NonEmptyString,
})

const dataSourceWithoutCreatedAtSchema = dataSourceSchema.omit("createdAt")
const dataSourceWithoutCreatedAtStandardSchema = Schema.standardSchemaV1(
  dataSourceWithoutCreatedAtSchema,
)
const encodeDataSourceWithoutCreatedAt = Schema.encodeSync(
  dataSourceWithoutCreatedAtSchema,
)

const dataSourceArrayAndMcpToolOptionArray = Schema.Struct({
  dataSourceArray: Schema.Array(dataSourceSchema),
  mcpToolNameArray: Schema.Array(Schema.NonEmptyString),
})
const decodeDataSourceArrayAndMcpToolOption = Schema.decodeSync(
  dataSourceArrayAndMcpToolOptionArray,
)

export const getHandler = Hono.factory.createHandlers(async (c) =>
  c.render(<GetDataSource {...(await fetchDataSourcesAndTools(c.var.db))} />),
)

export const postHandler = Hono.factory.createHandlers(
  sValidator("form", dataSourceWithoutCreatedAtStandardSchema),
  async (c) =>
    Effect.gen(function* () {
      const dataSource = yield* Option.fromIterable(
        yield* Effect.tryPromise(() =>
          c.var.db
            .insert(Drizzle.dataSourceTable)
            .values(c.req.valid("form"))
            .returning(),
        ),
      )
      return c.render(<PostComponent {...dataSource} />)
    }).pipe(Effect.runPromise),
)

export const deleteHandler = Hono.factory.createHandlers(
  sValidator("query", dataSourceWithoutCreatedAtStandardSchema),
  async (c) =>
    Effect.gen(function* () {
      const query = c.req.valid("query")

      yield* Effect.tryPromise(() =>
        c.var.db
          .delete(Drizzle.dataSourceTable)
          .where(
            and(
              eq(Drizzle.dataSourceTable.url, query.url),
              eq(Drizzle.dataSourceTable.mcpToolName, query.mcpToolName),
              eq(Drizzle.dataSourceTable.type, query.type),
            ),
          ),
      )

      return c.json(null)
    }).pipe(Effect.runPromise),
)

async function fetchDataSourcesAndTools(db: Database) {
  const [dataSourceArray, mcpToolOptionArray] = await db.batch([
    db.query.dataSourceTable.findMany({
      columns: {
        createdAt: true,
        mcpToolName: true,
        type: true,
        url: true,
      },
      orderBy(fields, operators) {
        return operators.desc(fields.createdAt)
      },
    }),
    db.query.mcpToolTable.findMany({
      columns: {
        name: true,
        title: true,
      },
      orderBy(fields, operators) {
        return operators.desc(fields.createdAt)
      },
    }),
  ])
  return decodeDataSourceArrayAndMcpToolOption({
    dataSourceArray,
    mcpToolNameArray: mcpToolOptionArray.map((v) => v.name),
  })
}

async function GetDataSource(
  props: typeof dataSourceArrayAndMcpToolOptionArray.Type,
) {
  const AddNewDataSourceModal = Modal.createModal("add-new-data-source-modal")

  const tableID = "mcp-tool-table"

  return (
    <div class="space-y-6">
      <H1Container>
        <h1 class="text-3xl font-bold">Data Sources</h1>
        <AddNewDataSourceModal.OpenButton class="btn btn-primary">
          <Icon.PlusIcon ariaLabel="Add Icon" size="sm" />
          Add New Data Source
        </AddNewDataSourceModal.OpenButton>
      </H1Container>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <SimpleStatCard.SimpleStatCard
          colorClass="text-primary"
          title="Total Data Sources"
          value={props.dataSourceArray.length}
        />
        <SimpleStatCard.SimpleStatCard
          colorClass="text-info"
          title="MCP Tools"
          value={props.mcpToolNameArray.length}
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
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {props.dataSourceArray.map((dataSource) => (
              <TableItem {...dataSource} />
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
            <Select.Select
              name="MCP Tool"
              selectAttributes={{
                id: "datasource-mcptool",
                name: "mcpToolName",
                required: true,
              }}
            >
              {props.mcpToolNameArray.map((name) => (
                <option value={name}>{name}</option>
              ))}
            </Select.Select>
            <Select.Select
              name="Type"
              selectAttributes={{
                id: `type`,
                name: `type`,
                required: true,
              }}
            >
              {availableDataSourceTypes.map((type) => (
                <option value={type.value}>{type.label}</option>
              ))}
            </Select.Select>
            <Input.Input
              inputAttributes={{
                id: `url`,
                name: `url`,
                placeholder: "https://example.com",
                required: true,
                type: "url",
              }}
              name="URL"
            ></Input.Input>

            <div class="modal-action">
              <button class="btn btn-primary" type="submit">
                <Icon.CheckIcon ariaLabel="Save Icon" size="sm" />
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

function PostComponent(props: typeof dataSourceSchema.Type) {
  return <TableItem {...props} />
}

function TableItem(props: typeof dataSourceSchema.Type) {
  return (
    <tr>
      <th>{props.mcpToolName}</th>
      <td>{props.type}</td>
      <td>{props.url}</td>
      <td>
        {Duration.formatShort(
          DateTime.unsafeFromDate(props.createdAt),
          DateTime.unsafeNow(),
          { locale: getDefaultLocale() },
        )}
      </td>
      <td>
        <button
          class="btn btn-error btn-sm"
          hx-delete={`/app/admin/data-source?${new URLSearchParams(
            encodeDataSourceWithoutCreatedAt({
              mcpToolName: props.mcpToolName,
              type: props.type,
              url: props.url,
            }),
          ).toString()}`}
          hx-swap="delete"
          hx-target="closest tr"
          type="button"
        >
          <Icon.DeleteIcon ariaLabel="Delete" size="sm" />
        </button>
      </td>
    </tr>
  )
}
