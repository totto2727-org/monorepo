import { Schema } from "@totto/function/effect"
import type { Create } from "@totto/function/effect/util"

export const schema = Schema.Struct({
  provider: Schema.NonEmptyString,
  providerUserEmail: Schema.NonEmptyString,
})

export const make: Create<typeof schema> = Schema.decodeSync(schema)
