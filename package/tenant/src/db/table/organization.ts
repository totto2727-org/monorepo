import { cuid2 } from "drizzle-cuid2/sqlite"
import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core"
import { createdAt, updatedAt } from "../column.js"

export const table = sqliteTable("organization", {
  createdAt,
  id: cuid2("id").primaryKey(),
  isPersonal: integer("is_personal", { mode: "boolean" }).notNull(),
  name: text("name").notNull(),
  updatedAt,
})
