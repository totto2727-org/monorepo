import { createdAt, updatedAt } from "@package/drizzle-orm/column"
import { cuid2 } from "drizzle-cuid2/sqlite"
import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core"

export const table = sqliteTable("organization", {
  createdAt,
  id: cuid2("id").primaryKey(),
  isPersonal: integer("is_personal", { mode: "boolean" }).notNull(),
  name: text("name").notNull(),
  updatedAt,
})
