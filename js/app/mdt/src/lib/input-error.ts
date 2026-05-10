import { Data } from 'effect'

export class InputError extends Data.TaggedError('InputError')<{
  readonly path: string
  readonly message: string
}> {}
