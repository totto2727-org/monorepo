import { Data } from 'effect'

export class ConfigFileError extends Data.TaggedError('ConfigFileError')<{
  readonly path: string
  readonly message: string
}> {}
