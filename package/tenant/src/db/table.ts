import { cuid2 } from "drizzle-cuid2/sqlite"
import { relations } from "drizzle-orm"
import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core"

const createdAt = integer("created_at", { mode: "timestamp" })
  .notNull()
  .$default(() => new Date())

const updatedAt = integer("updated_at", { mode: "timestamp" })
  .notNull()
  .$default(() => new Date())
  .$onUpdate(() => new Date())

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

export const clerkUserTable = sqliteTable("clerk_user", {
  clerkID: text("clerk_id").primaryKey(),
  createdAt,
  id: cuid2("id")
    .notNull()
    .unique()
    .references(() => userTable.id),
  updatedAt,
})

export const clerkOrganizationTable = sqliteTable("clerk_organization", {
  clerkID: text("clerk_id").primaryKey(),
  createdAt,
  id: cuid2("id")
    .notNull()
    .unique()
    .references(() => organizationTable.id),
  updatedAt,
})

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
  clerkUser: op.one(clerkUserTable),
  cloudflareAccessUser: op.one(cloudflareAccessUserTable),
}))

export const organizationRelation = relations(organizationTable, (op) => ({
  clerkOrganization: op.one(clerkOrganizationTable),
  cloudflareAccessOrganization: op.one(cloudflareAccessOrganizationTable),
}))

export const clerkUserRelation = relations(clerkUserTable, (op) => ({
  user: op.one(userTable),
}))

export const clerkOrganizationRelation = relations(
  clerkOrganizationTable,
  (op) => ({
    organization: op.one(organizationTable),
  }),
)

export const cloudflareAccessUserRelation = relations(
  cloudflareAccessUserTable,
  (op) => ({
    user: op.one(userTable),
  }),
)

export const cloudflareAccessOrganizationRelation = relations(
  cloudflareAccessOrganizationTable,
  (op) => ({
    organization: op.one(organizationTable),
  }),
)
