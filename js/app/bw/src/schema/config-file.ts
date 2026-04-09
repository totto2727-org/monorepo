import { Schema } from 'effect'

export const ConfigFile = Schema.Record(Schema.String, Schema.Unknown)
export type ConfigFile = typeof ConfigFile.Type
