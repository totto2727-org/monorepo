import { Effect } from 'effect'
import { Command, Flag, Prompt } from 'effect/unstable/cli'

import { getAgentsDir } from '#@/lib/paths.ts'
import * as LockFileService from '#@/service/lock-file.ts'
import * as Symlink from '#@/service/symlink.ts'

export const targetRemoveCommand = Command.make(
  'remove',
  {
    global: Flag.boolean('global').pipe(Flag.withAlias('g')),
  },
  (config) =>
    Effect.gen(function* () {
      const agentsDir = getAgentsDir(config.global)
      const lockFile = yield* LockFileService.read(agentsDir)

      if (lockFile.skillDirs.length === 0) {
        yield* Effect.log('No target directories registered.')
        return
      }

      const choices = lockFile.skillDirs.map((dir) => ({
        title: dir,
        value: dir,
      }))

      const toRemove = yield* Prompt.multiSelect({
        choices,
        message: 'Select target directories to remove:',
      })

      if (toRemove.length === 0) {
        yield* Effect.log('No directories selected.')
        return
      }

      const removeSet = new Set(toRemove)

      // Remove symlinks only from the selected directories (not .agents/skills/)
      const existingLinks = yield* Symlink.listSkillLinks(agentsDir)
      for (const dir of toRemove) {
        for (const link of existingLinks) {
          yield* Symlink.removeSkillLinkFromDirs([dir], link)
        }
      }

      const newLockFile = {
        ...lockFile,
        skillDirs: lockFile.skillDirs.filter((d) => !removeSet.has(d)),
      }
      yield* LockFileService.write(agentsDir, newLockFile)

      yield* Effect.log(`Removed ${toRemove.length} target directory(s).`)
    }),
).pipe(Command.withDescription('Remove skill symlink directories'))
