import type { TaggedErrorBaseType } from '@totto2727/fp/error'
import { Data } from 'effect'

export class TranslateError extends Data.TaggedError('TranslateError')<TaggedErrorBaseType> {}
