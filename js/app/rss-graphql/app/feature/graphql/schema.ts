import type { Context } from 'hono'

import SchemaBuilder from '@pothos/core'
import ValidationPlugin from '@pothos/plugin-validation'

export const makeBuilder = () =>
  new SchemaBuilder<{
    Context: Context
    DefaultInputFieldRequiredness: true
    DefaultFieldNullability: false
    Scalars: {
      NonEmptyString: {
        Input: string
        Output: string
      }
    }
  }>({
    defaultFieldNullability: false,
    defaultInputFieldRequiredness: true,
    plugins: [ValidationPlugin],
  })

export type Builder = ReturnType<typeof makeBuilder>
