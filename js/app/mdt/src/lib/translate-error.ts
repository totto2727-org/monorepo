import { Data } from 'effect'

export class TranslateError extends Data.TaggedError('TranslateError')<{
  readonly message: string
}> {}
