import { Schema } from "@totto/function/effect"
import { Cuid } from "@totto/function/effect/id"
import * as Organizaiton from "./organization.js"

export const schema = Schema.Struct({
  id: Cuid,
  name: Schema.String,
  organizationArray: Schema.NonEmptyArray(Organizaiton.schema),
})
