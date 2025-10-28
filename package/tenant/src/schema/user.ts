import { Schema } from "@totto/function/effect"
import * as CUID from "@totto/function/effect/cuid"
import type { Create } from "@totto/function/effect/util"
import * as Organization from "./organization.js"

export const schema = Schema.Struct({
  id: CUID.schema,
  name: Schema.String,
  organizationArray: Schema.NonEmptyArray(Organization.schema),
})

export const make: Create<typeof schema> = Schema.decodeSync(schema)
