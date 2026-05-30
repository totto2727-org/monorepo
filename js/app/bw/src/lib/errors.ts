import { Data } from 'effect'

import type { TaggedErrorBaseType } from '#@/lib/error.ts'

export class ConfigFileError extends Data.TaggedError('ConfigFileError')<
  TaggedErrorBaseType & {
    readonly path: string
  }
> {}
