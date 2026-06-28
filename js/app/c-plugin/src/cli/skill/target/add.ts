import { Effect, Path } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import { findNearestAgentsDir, getGlobalAgentsDir, normalizePathSpec, resolveSkillDirPath } from '#@/lib/paths.ts'
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
      const path = yield* Path.Path
      const normalizedPath = normalizePathSpec(config.path)
      const agentsDir = yield* config.global ? Effect.succeed(getGlobalAgentsDir()) : findNearestAgentsDir()
      const lockFileDir = path.dirname(agentsDir)
      const lockFile = yield* LockFileService.read(agentsDir)

      const resolved = resolveSkillDirPath(normalizedPath, lockFileDir)
      const isDuplicate = lockFile.skillDirs.some((d) => resolveSkillDirPath(d, lockFileDir) === resolved)
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
