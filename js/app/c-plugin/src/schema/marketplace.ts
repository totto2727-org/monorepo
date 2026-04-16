import { Schema } from 'effect'

// Claude Code / Cursor format
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

// Codex format
const CodexSource = Schema.Struct({
  path: Schema.String,
  source: Schema.String,
})

export const CodexMarketplacePlugin = Schema.Struct({
  category: Schema.optional(Schema.String),
  description: Schema.optional(Schema.String),
  name: Schema.String,
  policy: Schema.optional(
    Schema.Struct({
      authentication: Schema.optional(Schema.String),
      installation: Schema.optional(Schema.String),
    }),
  ),
  source: CodexSource,
})

export type CodexMarketplacePlugin = typeof CodexMarketplacePlugin.Type

export const CodexMarketplace = Schema.Struct({
  description: Schema.optional(Schema.String),
  name: Schema.String,
  plugins: Schema.Array(CodexMarketplacePlugin),
})

export type CodexMarketplace = typeof CodexMarketplace.Type

// Normalized representation (internal)
export interface NormalizedPlugin {
  readonly name: string
  readonly source: string
  readonly description?: string
}
