import { createdAt, updatedAt } from "@package/drizzle-orm/column"
import { cuid2 } from "drizzle-cuid2/sqlite"
import { relations } from "drizzle-orm"
import { foreignKey, sqliteTable, text } from "drizzle-orm/sqlite-core"
import * as User from "./user.js"
import * as UserLink from "./user-link.js"

export const table = sqliteTable(
  "primary_user_link",
  {
    createdAt,
    provider: text("provider").notNull(),
    updatedAt,
    userId: cuid2("user_id")
      .primaryKey()
      .references(() => User.table.id),
  },
  // biome-ignore lint/nursery/noShadow: shadowing is intentional
  (table) => [
    foreignKey({
      columns: [table.userId, table.provider],
      foreignColumns: [UserLink.table.userId, UserLink.table.provider],
    }),
  ],
)

export const primaryProviderRelation = relations(table, (op) => ({
  user: op.one(User.table, {
    fields: [table.userId],
    references: [User.table.id],
  }),
  userLink: op.one(UserLink.table, {
    fields: [table.provider],
    references: [UserLink.table.provider],
  }),
}))

export const userRelation = relations(User.table, (op) => ({
  primaryProvider: op.one(table, {
    fields: [User.table.id],
    references: [table.userId],
  }),
}))

export const userLinkRelation = relations(UserLink.table, (op) => ({
  primaryProvider: op.one(table, {
    fields: [UserLink.table.provider],
    references: [table.provider],
  }),
}))
