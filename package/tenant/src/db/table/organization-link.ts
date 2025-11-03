import { createdAt, updatedAt } from "@package/drizzle-orm/column"
import { cuid2 } from "drizzle-cuid2/sqlite"
import { relations } from "drizzle-orm"
import {
  primaryKey,
  sqliteTable,
  text,
  uniqueIndex,
} from "drizzle-orm/sqlite-core"
import * as Organization from "./organization.js"

export const table = sqliteTable(
  "organization_link",
  {
    createdAt,
    organizationId: cuid2("organization_id")
      .notNull()
      .references(() => Organization.table.id),
    provider: text("provider").notNull(),
    providerOrganizationId: text("provider_organization_id").notNull(),
    updatedAt,
  },
  // biome-ignore lint/nursery/noShadow: shadowing is intentional
  (table) => [
    primaryKey({ columns: [table.organizationId, table.provider] }),
    uniqueIndex("organization_link_unique_provider_organization_id_idx").on(
      table.providerOrganizationId,
      table.provider,
    ),
  ],
)

export const organizationRelation = relations(Organization.table, (op) => ({
  organizationLink: op.many(table),
}))

export const organizationLinkRelation = relations(table, (op) => ({
  organization: op.one(Organization.table, {
    fields: [table.organizationId],
    references: [Organization.table.id],
  }),
}))
