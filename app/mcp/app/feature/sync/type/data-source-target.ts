import { Schema } from "@totto/function/effect"
import * as DataSourceType from "./data-source-type.js"

export const schema = Schema.Struct({
  type: DataSourceType.schema,
  url: Schema.transform(Schema.NonEmptyString, Schema.instanceOf(URL), {
    decode: (str) => new URL(str),
    encode: (url) => url.toString(),
  }),
})

export const make = Schema.decodeSync(schema)
