import * as Fs from 'node:fs/promises'

import { Data, Effect, Schema } from 'effect'

import { parseJson } from '#@/lib/json.ts'
import { getLockFilePath } from '#@/lib/paths.ts'
import { LockFile as LockFileSchema, emptyLockFile } from '#@/schema/lock-file.ts'
import type { LockFile } from '#@/schema/lock-file.ts'

export class LockFileCorruptError extends Data.TaggedError('LockFileCorruptError')<{
  readonly path: string
  readonly cause: unknown
}> {}

const decode = Schema.decodeUnknownEffect(LockFileSchema)

export const read = (agentsDir: string): Effect.Effect<LockFile, LockFileCorruptError> =>
  Effect.tryPromise({
    catch: () => new LockFileCorruptError({ cause: 'file not found', path: getLockFilePath(agentsDir) }),
    try: () => Fs.readFile(getLockFilePath(agentsDir), 'utf-8'),
  }).pipe(
    Effect.flatMap((content) =>
      Effect.try({
        catch: (cause) => new LockFileCorruptError({ cause, path: getLockFilePath(agentsDir) }),
        try: () => parseJson(content),
      }).pipe(
        Effect.flatMap((parsed) =>
          decode(parsed).pipe(
            Effect.mapError(
              (cause) =>
                new LockFileCorruptError({
                  cause,
                  path: getLockFilePath(agentsDir),
                }),
            ),
          ),
        ),
      ),
    ),
    Effect.orElseSucceed(() => emptyLockFile),
  )

export const write = (agentsDir: string, lockFile: LockFile): Effect.Effect<void> =>
  Effect.tryPromise({
    catch: (e: unknown) => e,
    try: async () => {
      const path = getLockFilePath(agentsDir)
      const tmpPath = `${path}.tmp`
      const content = JSON.stringify(lockFile, null, '\t')
      await Fs.writeFile(tmpPath, `${content}\n`, 'utf-8')
      await Fs.rename(tmpPath, path)
    },
  }).pipe(Effect.ignore)
