import { Schema } from "@totto/function/effect"
import * as CUID from "@totto/function/effect/cuid"
import type { Create } from "@totto/function/effect/util"
import * as Organization from "./organization.js"
import * as UserLink from "./user-link.js"

export const schema = Schema.Struct({
  id: CUID.schema,
  name: Schema.NonEmptyString,
  organizationArray: Schema.NonEmptyArray(Organization.schema),
  primaryUserLink: UserLink.schema,
})

export const make: Create<typeof schema> = Schema.decodeSync(schema)
