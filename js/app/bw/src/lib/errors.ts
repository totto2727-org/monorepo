import type { TaggedErrorBaseType } from '@totto2727/fp/error'
import { Data } from 'effect'

export class ConfigFileError extends Data.TaggedError('ConfigFileError')<
  TaggedErrorBaseType & {
    readonly path: string
  }
> {}
