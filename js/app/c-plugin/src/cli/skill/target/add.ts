import { Effect } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import {
  expandHomePath,
  findNearestAgentsDir,
  getGlobalAgentsDir,
  hasHomePathPrefix,
  normalizePathSpec,
} from '#@/lib/paths.ts'
import * as LockFileService from '#@/service/lock-file.ts'
import * as SyncService from '#@/service/sync.ts'

export const targetAddCommand = Command.make(
  'add',
  {
    global: Flag.boolean('global').pipe(Flag.withAlias('g')),
    path: Argument.string('path'),
  },
  (config) =>
    Effect.gen(function* () {
      const normalizedPath = normalizePathSpec(config.path)
      if (!hasHomePathPrefix(normalizedPath)) {
        yield* Effect.fail(new Error(`Invalid target path: ${config.path}. Expected '~/...' (home path).`))
        return
      }

      const agentsDir = yield* config.global ? Effect.succeed(getGlobalAgentsDir()) : findNearestAgentsDir()
      const lockFile = yield* LockFileService.read(agentsDir)

      const expanded = expandHomePath(normalizedPath)
      const isDuplicate = lockFile.skillDirs.some((d) => expandHomePath(d) === expanded)
      if (isDuplicate) {
        yield* Effect.log(`Directory already registered: ${normalizedPath}`)
        return
      }

      const newLockFile = {
        ...lockFile,
        skillDirs: [...lockFile.skillDirs, normalizedPath],
      }
      yield* LockFileService.write(agentsDir, newLockFile)
      yield* Effect.log(`Added skill target directory: ${normalizedPath}`)

      yield* SyncService.run(agentsDir)
    }),
).pipe(Command.withDescription('Add a directory for skill symlinks'))
