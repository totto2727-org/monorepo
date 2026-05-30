import { Effect, FileSystem } from 'effect'
import { Command } from 'effect/unstable/cli'

import { getLockFilePath } from '#@/lib/paths.ts'
import { emptyLockFile } from '#@/schema/lock-file.ts'

export const initLockFile = (projectRoot: string): Effect.Effect<void, unknown, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const agentsDir = `${projectRoot}/.agents`
    const lockPath = getLockFilePath(agentsDir)

    yield* fs.makeDirectory(agentsDir, { recursive: true })
    yield* fs.writeFileString(lockPath, `${JSON.stringify(emptyLockFile, null, '\t')}\n`, { flag: 'wx' })
  })

export const initCommand = Command.make('init', {}, () => initLockFile(process.cwd())).pipe(
  Command.withDescription('Create an empty lock file in the current directory'),
)
