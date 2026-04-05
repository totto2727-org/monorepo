import { Schema } from 'effect'

export const MarketplacePlugin = Schema.Struct({
  description: Schema.optional(Schema.String),
  name: Schema.String,
  source: Schema.String,
})

export type MarketplacePlugin = typeof MarketplacePlugin.Type

export const Marketplace = Schema.Struct({
  description: Schema.optional(Schema.String),
  name: Schema.String,
  plugins: Schema.Array(MarketplacePlugin),
})

export type Marketplace = typeof Marketplace.Type
