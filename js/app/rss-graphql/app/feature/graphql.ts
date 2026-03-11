import { printSchema } from 'graphql'

import * as RSS from './graphql/rss.ts'
import { makeBuilder } from './graphql/schema.ts'

export const makeSchema = () => {
  const builder = makeBuilder()
  RSS.initGraphQL(builder)
  return builder.toSchema()
}

export const toFormattedString = (schema: ReturnType<typeof makeSchema>) => printSchema(schema)
