import { Schema } from "@totto/function/effect"
import { schema as dataSourceTargetSchema } from "./data-source-target.js"

export const schema = Schema.Struct({
  mcpToolName: Schema.NonEmptyString,
  dataSources: Schema.Array(dataSourceTargetSchema),
})