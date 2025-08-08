import { Schema } from "@totto/function/effect"

export const schema = Schema.Struct({
  name: Schema.NonEmptyString,
  title: Schema.NonEmptyString,
  description: Schema.NonEmptyString,
})