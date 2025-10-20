import type { HasDefault, HasRuntimeDefault, NotNull } from "drizzle-orm"
import {
  integer,
  type SQLiteTimestampBuilderInitial,
} from "drizzle-orm/sqlite-core"

export const createdAt: HasRuntimeDefault<
  HasDefault<NotNull<SQLiteTimestampBuilderInitial<"created_at">>>
> = integer("created_at", { mode: "timestamp" })
  .notNull()
  .$default(() => new Date())

export const updatedAt: HasDefault<
  HasRuntimeDefault<
    HasDefault<NotNull<SQLiteTimestampBuilderInitial<"updated_at">>>
  >
> = integer("updated_at", { mode: "timestamp" })
  .notNull()
  .$default(() => new Date())
  .$onUpdate(() => new Date())
