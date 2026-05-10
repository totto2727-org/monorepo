import { Data } from 'effect'

export class InvalidLocaleError extends Data.TaggedError('InvalidLocaleError')<{
  readonly input: string
}> {}
