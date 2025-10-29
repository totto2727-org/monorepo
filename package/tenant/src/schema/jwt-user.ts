import { Schema } from "@totto/function/effect"
import type { Create } from "@totto/function/effect/util"

export const schema = Schema.Struct({
  email: Schema.NonEmptyString,
  id: Schema.NonEmptyString,
  name: Schema.NonEmptyString,
  organizationArray: Schema.Array(
    Schema.Struct({
      id: Schema.NonEmptyString,
      name: Schema.NonEmptyString,
    }),
  ),
})

export const make: Create<typeof schema> = Schema.decodeSync(schema)
