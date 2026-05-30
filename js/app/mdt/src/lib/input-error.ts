import { Data } from 'effect'

import type { TaggedErrorBaseType } from '#@/lib/error.ts'

export class InputError extends Data.TaggedError('InputError')<
  TaggedErrorBaseType & {
    readonly path: string
  }
> {}
