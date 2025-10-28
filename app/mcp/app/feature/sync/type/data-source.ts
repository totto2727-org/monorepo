import { Schema } from "@totto/function/effect"

export const schema = Schema.Struct({
  createdAt: Schema.Union(Schema.DateFromSelf, Schema.DateFromString),
  mcpToolName: Schema.NonEmptyString,
  type: Schema.Literal("text", "firecrawl"),
  url: Schema.NonEmptyString,
})

export const make = Schema.decodeSync(schema)
