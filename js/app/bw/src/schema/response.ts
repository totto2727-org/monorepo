import { Schema } from 'effect'

export const SnapshotResponse = Schema.Struct({
  content: Schema.String,
  screenshot: Schema.String,
})
export type SnapshotResponse = typeof SnapshotResponse.Type

export const CrawlStartResponse = Schema.Struct({
  id: Schema.String,
})
export type CrawlStartResponse = typeof CrawlStartResponse.Type

export const CrawlStatusResponse = Schema.Struct({
  finished: Schema.optional(Schema.Number),
  status: Schema.String,
  total: Schema.optional(Schema.Number),
})
export type CrawlStatusResponse = typeof CrawlStatusResponse.Type
