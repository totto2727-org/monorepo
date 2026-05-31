import type { TaggedErrorBaseType } from '@totto2727/fp/error'
import { Data, Effect, FileSystem, Schema } from 'effect'

import { parseJson } from '#@/lib/json.ts'
import { getLockFilePath } from '#@/lib/paths.ts'
import { LockFile as LockFileSchema, emptyLockFile } from '#@/schema/lock-file.ts'
import type { LockFile } from '#@/schema/lock-file.ts'

export class LockFileCorruptError extends Data.TaggedError('LockFileCorruptError')<
  TaggedErrorBaseType & {
    readonly path: string
  }
> {}

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- input is unknown (file content)
const decode = Schema.decodeUnknownEffect(LockFileSchema)

export const read = (agentsDir: string): Effect.Effect<LockFile, LockFileCorruptError, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    return yield* fs.readFileString(getLockFilePath(agentsDir)).pipe(
      Effect.mapError(
        (cause) =>
          new LockFileCorruptError({
            error: cause,
            path: getLockFilePath(agentsDir),
          }),
      ),
    )
  }).pipe(
    Effect.flatMap((content) =>
      Effect.try({
        catch: (cause) =>
          new LockFileCorruptError({
            error: cause,
            path: getLockFilePath(agentsDir),
          }),
        try: () => parseJson(content),
      }).pipe(
        Effect.flatMap((parsed) =>
          decode(parsed).pipe(
            Effect.mapError(
              (cause) =>
                new LockFileCorruptError({
                  error: cause,
                  path: getLockFilePath(agentsDir),
                }),
            ),
          ),
        ),
      ),
    ),
    Effect.orElseSucceed(() => emptyLockFile),
  )

export const write = (agentsDir: string, lockFile: LockFile): Effect.Effect<void, never, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const path = getLockFilePath(agentsDir)
    const tmpPath = `${path}.tmp`
    const content = JSON.stringify(lockFile, null, '\t')
    yield* fs.writeFileString(tmpPath, `${content}\n`).pipe(Effect.ignore)
    yield* fs.rename(tmpPath, path).pipe(Effect.ignore)
  })
