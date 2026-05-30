import type { TaggedErrorBaseData } from '@totto2727/fp/error'
import { Data } from 'effect'

export class ConfigFileError extends Data.TaggedError('ConfigFileError')<
  TaggedErrorBaseData & {
    readonly path: string
  }
> {}
