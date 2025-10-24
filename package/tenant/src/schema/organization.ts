import { Schema } from "@totto/function/effect"
import * as CUID from "@totto/function/effect/cuid"

export const schema = Schema.Struct({
  id: CUID.schema,
  isPersonal: Schema.Boolean,
  name: Schema.String,
})
