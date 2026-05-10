import { access, readFile, writeFile } from 'node:fs/promises'

import { Effect } from 'effect'

import { InputError } from '#@/lib/input-error.ts'
import { OutputExistsError } from '#@/lib/output-exists-error.ts'

const fileExists = (path: string): Effect.Effect<boolean> =>
  Effect.promise(async () => {
    try {
      await access(path)
      return true
    } catch {
      return false
    }
  })

export const readText = (path: string): Effect.Effect<string, InputError> =>
  Effect.tryPromise({
    catch: (error) =>
      new InputError({
        message: error instanceof Error ? error.message : String(error),
        path,
      }),
    try: () => readFile(path, 'utf-8'),
  })

export const writeText = (
  path: string,
  text: string,
  force: boolean,
): Effect.Effect<void, InputError | OutputExistsError> =>
  Effect.gen(function* () {
    if (!force) {
      const exists = yield* fileExists(path)
      if (exists) {
        return yield* Effect.fail(new OutputExistsError({ path }))
      }
    }
    return yield* Effect.tryPromise({
      catch: (error) =>
        new InputError({
          message: error instanceof Error ? error.message : String(error),
          path,
        }),
      try: () => writeFile(path, text, 'utf-8'),
    })
  })
