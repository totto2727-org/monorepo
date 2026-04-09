import { Effect } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import { getAgentsDir, getRepoCacheDir } from '#@/lib/paths.ts'
import type { LockFile } from '#@/schema/lock-file.ts'
import * as Cache from '#@/service/cache.ts'
import * as Git from '#@/service/git.ts'
import * as LockFileService from '#@/service/lock-file.ts'
import * as SyncService from '#@/service/sync.ts'

export const updateCommand = Command.make(
  'update',
  {
    global: Flag.boolean('global').pipe(Flag.withAlias('g')),
    recursive: Flag.boolean('recursive').pipe(Flag.withAlias('r')),
  },
  (config) =>
    Effect.gen(function* () {
      yield* Git.checkInstalled

      const agentsDir = getAgentsDir(config.global)
      yield* Cache.ensureDirs(agentsDir)

      const lockFile = yield* LockFileService.read(agentsDir)
      if (lockFile.repositories.length === 0) {
        yield* Effect.log('No repositories in lock file.')
        return
      }

      const updatedRepos: LockFile['repositories'][number][] = []

      for (const repo of lockFile.repositories) {
        const repoDir = getRepoCacheDir(agentsDir, repo.source)
        yield* Effect.log(`Updating ${repo.source}...`)
        yield* Git.pull(repoDir)
        const newCommitHash = yield* Git.revParseHead(repoDir)
        updatedRepos.push({ ...repo, commitHash: newCommitHash })
      }

      const newLockFile: LockFile = {
        ...lockFile,
        repositories: updatedRepos,
      }

      yield* LockFileService.write(agentsDir, newLockFile)
      yield* SyncService.run(agentsDir)
    }),
).pipe(Command.withDescription('Update skills to latest'))
