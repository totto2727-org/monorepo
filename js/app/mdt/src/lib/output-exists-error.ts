import { Data } from 'effect'

export class OutputExistsError extends Data.TaggedError('OutputExistsError')<{
  readonly path: string
}> {}
