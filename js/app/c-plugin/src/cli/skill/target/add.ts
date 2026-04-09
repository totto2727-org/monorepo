import { Effect } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import { getAgentsDir } from '#@/lib/paths.ts'
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
      const agentsDir = getAgentsDir(config.global)
      const lockFile = yield* LockFileService.read(agentsDir)

      if (lockFile.skillDirs.includes(config.path)) {
        yield* Effect.log(`Directory already registered: ${config.path}`)
        return
      }

      const newLockFile = {
        ...lockFile,
        skillDirs: [...lockFile.skillDirs, config.path],
      }
      yield* LockFileService.write(agentsDir, newLockFile)
      yield* Effect.log(`Added skill target directory: ${config.path}`)

      yield* SyncService.run(agentsDir)
    }),
).pipe(Command.withDescription('Add a directory for skill symlinks'))
