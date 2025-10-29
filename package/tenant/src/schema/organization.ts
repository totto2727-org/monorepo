import { Schema } from "@totto/function/effect"
import * as CUID from "@totto/function/effect/cuid"
import type { Create } from "@totto/function/effect/util"

export const schema = Schema.Struct({
  id: CUID.schema,
  isPersonal: Schema.Boolean,
  name: Schema.NonEmptyString,
})

export const make: Create<typeof schema> = Schema.decodeSync(schema)
