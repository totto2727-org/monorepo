import { drizzle } from "drizzle-orm/d1"
import * as schema from "#@/drizzle.js"

export function create(db: D1Database) {
  return drizzle(db, { schema })
}

export type Database = ReturnType<typeof create>
export { schema }
