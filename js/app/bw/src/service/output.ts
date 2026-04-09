import { writeFile as fsWriteFile } from 'node:fs/promises'

import { Console, Data, Effect } from 'effect'

export class OutputError extends Data.TaggedError('OutputError')<{
  readonly path: string
  readonly message: string
}> {}

export const writeFile = (path: string, data: Uint8Array): Effect.Effect<void, OutputError> =>
  Effect.tryPromise({
    catch: (error) => new OutputError({ message: error instanceof Error ? error.message : String(error), path }),
    try: () => fsWriteFile(path, data),
  })

export const writeText = (path: string, text: string): Effect.Effect<void, OutputError> =>
  Effect.tryPromise({
    catch: (error) => new OutputError({ message: error instanceof Error ? error.message : String(error), path }),
    try: () => fsWriteFile(path, text, 'utf8'),
  })

export const printJson = (data: unknown): Effect.Effect<void> => Console.log(JSON.stringify(data, null, 2))

export const printText = (text: string): Effect.Effect<void> => Console.log(text)
