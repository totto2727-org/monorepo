import SchemaBuilder from "@pothos/core"
import ValidationPlugin from "@pothos/plugin-validation"
import type { Context } from "../hono.js"

export const builder = new SchemaBuilder<{
  Context: Context
}>({
  plugins: [ValidationPlugin],
})
