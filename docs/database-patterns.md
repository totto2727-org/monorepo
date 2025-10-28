# Database Patterns

This document defines database patterns using Drizzle ORM.

## Table Definition

### Basic table

Define tables with common columns:

```typescript
import { cuid2 } from "drizzle-cuid2/sqlite"
import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core"
import { createdAt, updatedAt } from "./column.js"

export const userTable = sqliteTable("user", {
  createdAt,
  id: cuid2("id").primaryKey(),
  name: text("name").notNull(),
  updatedAt,
})
```

### Naming conventions

- **Table name (DB)**: `snake_case`
  - Example: `user`, `organization`, `cloudflare_access_user`
- **Column name (DB)**: `snake_case`
  - Example: `cloudflare_access_id`, `is_personal`, `created_at`
- **Variable name (TS)**: `camelCase` + `Table` suffix
  - Example: `userTable`, `organizationTable`, `cloudflareAccessUserTable`

## Common Column Definitions

Define common columns in a separate file for reuse:

```typescript
import { integer, type SQLiteTimestampBuilderInitial } from "drizzle-orm/sqlite-core"

export const createdAt = integer("created_at", { mode: "timestamp" })
  .notNull()
  .$default(() => new Date())

export const updatedAt = integer("updated_at", { mode: "timestamp" })
  .notNull()
  .$default(() => new Date())
  .$onUpdate(() => new Date())
```

**Usage**:

- `.$default()`: Default value (on record creation)
- `.$onUpdate()`: Value on update

## Primary Keys

Use `cuid2()` from `drizzle-cuid2`:

```typescript
import { cuid2 } from "drizzle-cuid2/sqlite"

export const userTable = sqliteTable("user", {
  id: cuid2("id").primaryKey(),
})
```

## Relation Definitions

Define relations bidirectionally:

```typescript
import { relations } from "drizzle-orm"

export const userRelation = relations(userTable, (op) => ({
  cloudflareAccessUser: op.one(cloudflareAccessUserTable),
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
```

**Naming conventions**:

- Relation variables: `〜Relation` suffix

## Query Operations and Option Integration

Choose the appropriate query method based on context:

- **Applications (`@app/*`)**: Use `query` API (principle)
- **Packages (`@package/*`)**: Use `select` API

### Using query API (Applications)

Use the query API for application code to maintain consistency:

```typescript
const userOption = Option.fromIterable(
  await db.query.userTable.findMany({
    where: eq(userTable.id, userId),
    columns: {
      id: true,
      name: true,
    },
  }),
)

const user = Option.getOrThrow(userOption)
```

### Using select API (Packages)

Use the select API for package code that requires fine-grained control:

```typescript
const userOption = Option.fromIterable(
  await db
    .select({
      id: userTable.id,
      name: userTable.name,
    })
    .from(userTable)
    .where(eq(userTable.id, userId)),
)

const user = Option.getOrThrow(userOption)
```

### Insert with returning

```typescript
const result = await db
  .insert(userTable)
  .values({
    id: userID,
    name: userID,
  })
  .returning()

const userOption = Option.fromIterable(result)
```

### Batch operations

```typescript
const result = await db.batch([
  db.insert(userTable).values({ id: userID, name: userID }).returning(),
  db.insert(organizationTable).values({ id: orgID, name: orgID }),
] as const)

const userOption = Option.fromIterable(result[0])
```

## Integration with Effect Schema

```typescript
import { Schema } from "@totto/function/effect"

export const schema = Schema.Struct({
  id: CUID.schema,
  name: Schema.String,
  organizationArray: Schema.NonEmptyArray(Organization.schema),
})
```

**Decoding**:

```typescript
const decodeOptionUser = Schema.decodeOption(User.schema)
c.set("user", decodeOptionUser(rawUser))
```

**Obtaining types**:

```typescript
type UserType = typeof schema.Type
type UserEncoded = typeof schema.Encoded
```
