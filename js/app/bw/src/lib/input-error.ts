import type { TaggedErrorBaseData } from '@totto2727/fp/error'
import { Data } from 'effect'

export class InputError extends Data.TaggedError('InputError')<TaggedErrorBaseData> {}
