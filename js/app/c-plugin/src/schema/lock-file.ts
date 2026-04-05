import { Schema } from 'effect'

export const PluginEntry = Schema.Struct({
  enabledSkills: Schema.Array(Schema.String),
  name: Schema.String,
  path: Schema.String,
})

export type PluginEntry = typeof PluginEntry.Type

export const RepositoryEntry = Schema.Struct({
  commitHash: Schema.String,
  plugins: Schema.Array(PluginEntry),
  source: Schema.String,
  sourceType: Schema.Literal('github'),
})

export type RepositoryEntry = typeof RepositoryEntry.Type

export const LockFile = Schema.Struct({
  repositories: Schema.Array(RepositoryEntry),
  version: Schema.Literal(1),
})

export type LockFile = typeof LockFile.Type

export const emptyLockFile: LockFile = {
  repositories: [],
  version: 1,
}
