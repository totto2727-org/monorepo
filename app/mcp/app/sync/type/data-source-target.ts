import { Schema } from "@totto/function/effect"
import { schema as dataSourceTypeSchema } from "./data-source-type.js"

export const schema = Schema.Struct({
  type: dataSourceTypeSchema,
  url: Schema.transform(
    Schema.NonEmptyString,
    Schema.instanceOf(URL),
    {
      decode: (str) => new URL(str),
      encode: (url) => url.toString(),
    },
  ),
})