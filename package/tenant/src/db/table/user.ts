import { cuid2 } from "drizzle-cuid2/sqlite"
import { sqliteTable, text } from "drizzle-orm/sqlite-core"
import { createdAt, updatedAt } from "../column.js"

export const table = sqliteTable("user", {
  createdAt,
  id: cuid2("id").primaryKey(),
  name: text("name").notNull(),
  updatedAt,
})
