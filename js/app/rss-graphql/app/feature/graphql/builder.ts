import type { Runtime } from '@totto/function/effect'
import type { HttpClient } from '@totto/function/effect/platform'

import SchemaBuilder from '@pothos/core'
import ValidationPlugin from '@pothos/plugin-validation'

export const builder = new SchemaBuilder<{
  Context: {
    runtime: Runtime.Runtime<HttpClient.HttpClient>
  }
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
