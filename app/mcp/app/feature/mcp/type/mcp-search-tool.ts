import { Schema } from "@totto/function/effect"

export const schema = Schema.Struct({
  description: Schema.NonEmptyString,
  name: Schema.NonEmptyString,
  title: Schema.NonEmptyString,
})

export const make = Schema.decodeSync(schema)
