import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core"

export const casbinRule = sqliteTable("casbin_rule", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  ptype: text("ptype").notNull(),
  v0: text("v0"),
  v1: text("v1"),
  v2: text("v2"),
  v3: text("v3"),
  v4: text("v4"),
  v5: text("v5"),
})
