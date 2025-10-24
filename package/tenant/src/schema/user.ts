import { Schema } from "@totto/function/effect"
import * as CUID from "@totto/function/effect/cuid"
import * as Organizaiton from "./organization.js"

export const schema = Schema.Struct({
  id: CUID.schema,
  name: Schema.String,
  organizationArray: Schema.NonEmptyArray(Organizaiton.schema),
})
