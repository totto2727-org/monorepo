import type { FileSystem } from 'effect'
import { Array, Effect, Path } from 'effect'

import { getRepoCacheDir } from '#@/lib/paths.ts'
import type { LockFile } from '#@/schema/lock-file.ts'
import * as Cache from '#@/service/cache.ts'
import * as Git from '#@/service/git.ts'
import * as LockFileService from '#@/service/lock-file.ts'
import * as SyncService from '#@/service/sync.ts'

export const run = (
  agentsDir: string,
): Effect.Effect<
  void,
  Error | Git.GitError | LockFileService.LockFileCorruptError,
  FileSystem.FileSystem | Path.Path
> =>
  Effect.gen(function* () {
    const path = yield* Path.Path
    const agentsRoot = path.dirname(agentsDir)
    yield* Cache.ensureDirs(agentsDir, agentsRoot)

    const lockFile = yield* LockFileService.read(agentsDir)
    if (Array.isReadonlyArrayEmpty(lockFile.repositories)) {
      yield* Effect.log('No repositories in lock file.')
      return
    }

    if (lockFile.repositories.some((r) => r.sourceType === 'github')) {
      yield* Git.checkInstalled
    }

    const updatedRepos: LockFile['repositories'][number][] = []

    for (const repo of lockFile.repositories) {
      if (repo.sourceType === 'local') {
        updatedRepos.push(repo)
        continue
      }
      const repoDir = getRepoCacheDir(agentsRoot, repo.source)
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
  })
