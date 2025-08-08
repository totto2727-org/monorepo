import { Schema } from "@totto/function/effect"
import { schema as mcpSearchToolSchema } from "./mcp-search-tool.js"

export const schema = Schema.Struct({
  name: Schema.NonEmptyString,
  version: Schema.NonEmptyString,
  ai: Schema.Any,
  sources: Schema.Array(mcpSearchToolSchema),
})