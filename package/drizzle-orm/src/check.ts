import { type SQL, sql } from "drizzle-orm"
import { check } from "drizzle-orm/sqlite-core"

export function cuidWithPrefix(column: SQL, prefix: string) {
  return check(
    "cuid_with_prefix",
    sql`${column} regexp "${prefix}:(system:)?[a-z][a-z0-9]*"`,
  )
}
