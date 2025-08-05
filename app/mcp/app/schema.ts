import { sql } from "drizzle-orm"
import { integer, primaryKey, sqliteTable, text } from "drizzle-orm/sqlite-core"

export const mcpTool = sqliteTable("mcp_tool", {
  createdAt: integer("created_at", { mode: "timestamp" })
    .notNull()
    .default(sql`(unixepoch())`),
  description: text("description").notNull(),
  lastUsed: text("last_used").notNull().default(sql`(unixepoch())`),
  name: text("name").primaryKey(),
  title: text("title").notNull(),
})

export const dataSource = sqliteTable(
  "data_source",
  {
    createdAt: text("created_at").notNull().default(sql`(unixepoch())`),
    mcpToolName: text("mcp_tool_name")
      .notNull()
      .references(() => mcpTool.name, { onDelete: "cascade" }),
    type: text("type", { enum: ["text", "firecrawl"] }).notNull(),
    url: text("url").notNull(),
  },
  (table) => [
    primaryKey({ columns: [table.url, table.mcpToolName, table.type] }),
  ],
)
