import { printSchema } from 'graphql'

import { builder } from './graphql/builder.ts'
import './graphql/rss.ts'

export const generateSchema = () => printSchema(builder.toSchema())
