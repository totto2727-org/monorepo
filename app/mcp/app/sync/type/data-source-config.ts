import { Schema } from "@totto/function/effect"
import * as DataSourceTarget from "./data-source-target.js"

export const schema = Schema.Struct({
  dataSources: Schema.Array(DataSourceTarget.schema),
  mcpToolName: Schema.NonEmptyString,
})
