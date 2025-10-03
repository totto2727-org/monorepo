import { printSchema } from "graphql"
import { builder } from "./graphql/builder.js"

import "./graphql/rss.js"

export * from "./graphql/builder.js"

export function generateSchema() {
  return printSchema(builder.toSchema())
}
