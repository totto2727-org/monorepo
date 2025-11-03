import { createdAt, updatedAt } from "@package/drizzle-orm/column"
import { cuid2 } from "drizzle-cuid2/sqlite"
import { relations } from "drizzle-orm"
import {
  primaryKey,
  sqliteTable,
  text,
  uniqueIndex,
} from "drizzle-orm/sqlite-core"
import * as User from "./user.js"

export const table = sqliteTable(
  "user_link",
  {
    createdAt,
    provider: text("provider").notNull(),
    providerUserEmail: text("provider_user_email").notNull(),
    providerUserId: text("provider_user_id").notNull(),
    updatedAt,
    userId: cuid2("user_id")
      .notNull()
      .references(() => User.table.id),
  },
  // biome-ignore lint/nursery/noShadow: shadowing is intentional
  (table) => [
    primaryKey({ columns: [table.userId, table.provider] }),
    uniqueIndex("user_link_unique_provider_user_id_email_idx").on(
      table.providerUserId,
      table.provider,
    ),
    uniqueIndex("user_link_unique_provider_user_email_idx").on(
      table.providerUserEmail,
      table.provider,
    ),
  ],
)

export const userRelation = relations(User.table, (op) => ({
  userLink: op.many(table),
}))

export const userLinkRelation = relations(table, (op) => ({
  user: op.one(User.table, {
    fields: [table.userId],
    references: [User.table.id],
  }),
}))
