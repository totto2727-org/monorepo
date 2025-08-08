import { Schema } from "@totto/function/effect"
import * as McpSearchTool from "./mcp-search-tool.js"

export const schema = Schema.Struct({
  ai: Schema.Any,
  name: Schema.NonEmptyString,
  sources: Schema.Array(McpSearchTool.schema),
  version: Schema.NonEmptyString,
})
