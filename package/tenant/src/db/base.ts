import { cuid2 } from "drizzle-cuid2/sqlite"
import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core"
import { createdAt, updatedAt } from "./column.js"

export const userTable = sqliteTable("user", {
  createdAt,
  id: cuid2("id").primaryKey(),
  name: text("name").notNull(),
  updatedAt,
})

export const organizationTable = sqliteTable("organization", {
  createdAt,
  id: cuid2("id").primaryKey(),
  isPersonal: integer("is_personal", { mode: "boolean" }).notNull(),
  name: text("name").notNull(),
  updatedAt,
})
