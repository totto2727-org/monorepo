import { drizzle } from "drizzle-orm/d1"
import * as schema from "#@/schema.js"

export function createDatabase(db: D1Database) {
  return drizzle(db, { schema })
}

export type Database = ReturnType<typeof createDatabase>
export { schema }
