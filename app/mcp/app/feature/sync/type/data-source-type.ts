import { Schema } from "@totto/function/effect"

export const schema = Schema.Literal("text", "firecrawl")

export const make = Schema.decodeSync(schema)
