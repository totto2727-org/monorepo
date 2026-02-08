import { printSchema } from 'graphql'

import { builder } from './graphql/builder.js'
import './graphql/rss.js'

export const generateSchema = () => printSchema(builder.toSchema())
