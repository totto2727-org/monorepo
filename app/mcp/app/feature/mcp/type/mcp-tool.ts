import { Schema } from "@totto/function/effect"

export const schema = Schema.Struct({
  description: Schema.NonEmptyString,
  lastUsed: Schema.Union(Schema.DateFromString, Schema.DateFromSelf),
  name: Schema.NonEmptyString,
  title: Schema.NonEmptyString,
})

export const make = Schema.decodeSync(schema)
