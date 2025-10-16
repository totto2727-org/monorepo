import { Schema } from "@totto/function/effect"
import { Cuid } from "@totto/function/effect/id"

export const schema = Schema.Struct({
  id: Cuid,
  isPersonal: Schema.Boolean,
  name: Schema.String,
})
