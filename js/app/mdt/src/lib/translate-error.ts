import { Data } from 'effect'

import type { TaggedErrorBaseType } from '#@/lib/error.ts'

export class TranslateError extends Data.TaggedError('TranslateError')<TaggedErrorBaseType> {}
