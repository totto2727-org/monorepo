import { Schema } from 'effect'

export const SnapshotApiResponse = Schema.Struct({
  result: Schema.Struct({
    content: Schema.String,
    screenshot: Schema.String,
  }),
  success: Schema.Boolean,
})
export type SnapshotResult = (typeof SnapshotApiResponse.Type)['result']

export const CrawlStartApiResponse = Schema.Struct({
  result: Schema.String,
  success: Schema.Boolean,
})

export const CrawlStatusApiResponse = Schema.Struct({
  result: Schema.Struct({
    finished: Schema.optional(Schema.Number),
    status: Schema.String,
    total: Schema.optional(Schema.Number),
  }),
  success: Schema.Boolean,
})
export type CrawlStatusResult = (typeof CrawlStatusApiResponse.Type)['result']
