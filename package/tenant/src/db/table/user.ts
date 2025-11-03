import { createdAt, updatedAt } from "@package/drizzle-orm/column"
import { cuid2 } from "drizzle-cuid2/sqlite"
import { sqliteTable, text } from "drizzle-orm/sqlite-core"

export const table = sqliteTable("user", {
  createdAt,
  id: cuid2("id").primaryKey(),
  name: text("name").notNull(),
  updatedAt,
})
