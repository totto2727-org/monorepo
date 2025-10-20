import { cuid2 } from "drizzle-cuid2/sqlite"
import { relations } from "drizzle-orm"
import { sqliteTable, text } from "drizzle-orm/sqlite-core"
import * as Base from "./base.js"
import { createdAt, updatedAt } from "./column.js"

export const userTable = Base.userTable
export const organizationTable = Base.organizationTable

export const cloudflareAccessUserTable = sqliteTable("cloudflare_access_user", {
  cloudflareAccessID: text("cloudflare_access_id").primaryKey(),
  createdAt,
  id: cuid2("id")
    .notNull()
    .unique()
    .references(() => userTable.id),
  updatedAt,
})

export const cloudflareAccessOrganizationTable = sqliteTable(
  "cloudflare_access_organization",
  {
    cloudflareAccessID: text("cloudflare_access_id").primaryKey(),
    createdAt,
    id: cuid2("id")
      .notNull()
      .unique()
      .references(() => organizationTable.id),
    updatedAt,
  },
)

export const userRelation = relations(userTable, (op) => ({
  cloudflareAccessUser: op.one(cloudflareAccessUserTable),
}))

export const organizationRelation = relations(organizationTable, (op) => ({
  cloudflareAccessOrganization: op.one(cloudflareAccessOrganizationTable),
}))

export const cloudflareAccessUserRelation = relations(
  cloudflareAccessUserTable,
  (op) => ({
    user: op.one(userTable, {
      fields: [cloudflareAccessUserTable.id],
      references: [userTable.id],
    }),
  }),
)

export const cloudflareAccessOrganizationRelation = relations(
  cloudflareAccessOrganizationTable,
  (op) => ({
    organization: op.one(organizationTable, {
      fields: [cloudflareAccessOrganizationTable.id],
      references: [organizationTable.id],
    }),
  }),
)
