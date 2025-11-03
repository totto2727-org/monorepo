import { createdAt } from "@package/drizzle-orm/column"
import { sql } from "drizzle-orm"
import { integer, primaryKey, sqliteTable, text } from "drizzle-orm/sqlite-core"

export const mcpToolTable = sqliteTable("mcp_tool", {
  createdAt,
  description: text("description").notNull(),
  lastUsed: integer("last_used", { mode: "timestamp" })
    .notNull()
    .default(sql`(unixepoch())`),
  name: text("name").primaryKey(),
  title: text("title").notNull(),
})

export const dataSourceTable = sqliteTable(
  "data_source",
  {
    createdAt: integer("created_at", { mode: "timestamp" })
      .notNull()
      .default(sql`(unixepoch())`),
    mcpToolName: text("mcp_tool_name")
      .notNull()
      .references(() => mcpToolTable.name, { onDelete: "cascade" }),
    type: text("type", { enum: ["text", "firecrawl"] }).notNull(),
    url: text("url").notNull(),
  },
  (table) => [
    primaryKey({ columns: [table.url, table.mcpToolName, table.type] }),
  ],
)
