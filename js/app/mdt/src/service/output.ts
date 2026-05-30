import { Effect, FileSystem } from 'effect'

import { InputError } from '#@/lib/input-error.ts'
import { OutputExistsError } from '#@/lib/output-exists-error.ts'

const fileExists = (path: string): Effect.Effect<boolean, never, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    return yield* fs.exists(path).pipe(Effect.orElseSucceed(() => false))
  })

export const readText = (path: string): Effect.Effect<string, InputError, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    return yield* fs.readFileString(path).pipe(
      Effect.mapError(
        (error) =>
          new InputError({
            error,
            path,
          }),
      ),
    )
  })

export const writeText = (
  path: string,
  text: string,
  force: boolean,
): Effect.Effect<void, InputError | OutputExistsError, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    if (!force) {
      const exists = yield* fileExists(path)
      if (exists) {
        return yield* Effect.fail(new OutputExistsError({ path }))
      }
    }
    const fs = yield* FileSystem.FileSystem
    return yield* fs.writeFileString(path, text).pipe(
      Effect.mapError(
        (error) =>
          new InputError({
            error,
            path,
          }),
      ),
    )
  })
