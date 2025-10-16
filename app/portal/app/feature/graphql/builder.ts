import SchemaBuilder from "@pothos/core"
import ValidationPlugin from "@pothos/plugin-validation"
import type { Context } from "../hono.js"

export const create = () =>
  new SchemaBuilder<{
    Context: Context
    DefaultInputFieldRequiredness: true
    DefaultFieldNullability: false
  }>({
    defaultFieldNullability: false,
    defaultInputFieldRequiredness: true,
    plugins: [ValidationPlugin],
  })

export type Builder = ReturnType<typeof create>
