import { Console, Data, Effect, FileSystem } from 'effect'

import { errorMessageOrDefault } from '#@/lib/error.ts'

export class OutputError extends Data.TaggedError('OutputError')<{
  readonly path: string
  readonly message: string
}> {}

export const writeFile = (path: string, data: Uint8Array): Effect.Effect<void, OutputError, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    return yield* fs
      .writeFile(path, data)
      .pipe(Effect.mapError((error) => new OutputError({ message: errorMessageOrDefault(error), path })))
  })

export const writeText = (path: string, text: string): Effect.Effect<void, OutputError, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    return yield* fs
      .writeFileString(path, text)
      .pipe(Effect.mapError((error) => new OutputError({ message: errorMessageOrDefault(error), path })))
  })

export const printJson = (data: unknown): Effect.Effect<void> => Console.log(JSON.stringify(data, null, 2))

export const printText = (text: string): Effect.Effect<void> => Console.log(text)
