import { Context } from "@totto/function/effect"
import { drizzle } from "drizzle-orm/d1"
import * as schema from "./drizzle/schema.js"

export function makeClient(d1: D1Database) {
  return drizzle(d1, {
    schema,
  })
}

export type Client = ReturnType<typeof makeClient>

export class Database extends Context.Tag("Database")<
  Database,
  () => Client
>() {}
