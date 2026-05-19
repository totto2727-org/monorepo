import * as NodePath from 'node:path'

import { Array, Effect } from 'effect'

import type { LockFile } from '#@/schema/lock-file.ts'
import * as Cache from '#@/service/cache.ts'
import * as Git from '#@/service/git.ts'
import * as GitIgnore from '#@/service/gitignore.ts'
import * as LockFileService from '#@/service/lock-file.ts'
import * as SkillResolver from '#@/service/skill-resolver.ts'
import * as Symlink from '#@/service/symlink.ts'

export const run = (
  agentsDir: string,
): Effect.Effect<void, Error | Git.GitError | LockFileService.LockFileCorruptError> =>
  Effect.gen(function* () {
    yield* Cache.ensureDirs(agentsDir)

    const lockFile = yield* LockFileService.read(agentsDir)
    if (Array.isReadonlyArrayEmpty(lockFile.repositories)) {
      yield* Effect.log('No repositories in lock file.')
      return
    }

    const hasGithubRepos = lockFile.repositories.some((r) => r.sourceType === 'github')
    if (hasGithubRepos) {
      yield* Git.checkInstalled
    }

    const agentsRoot = NodePath.dirname(agentsDir)
    const updatedRepos: LockFile['repositories'][number][] = []

    for (const repo of lockFile.repositories) {
      yield* Effect.log(`Syncing ${repo.source}...`)
      const repoDir =
        repo.sourceType === 'local'
          ? yield* Cache.ensureLocalPath(repo.source, agentsRoot)
          : yield* Cache.ensureRepo(agentsDir, repo.source)

      if (repo.sourceType !== 'local') {
        yield* Git.checkout(repoDir, repo.commitHash)
      }

      const availableSkills = yield* SkillResolver.resolveFromRepo(repoDir, repo.marketplaceKind)
      const availableNames = new Set(availableSkills.map((s) => s.skillName))

      const removedSkills: string[] = []
      const updatedPlugins = repo.plugins
        .map((plugin) => {
          const validSkills = plugin.enabledSkills.filter((s) => {
            if (!availableNames.has(s)) {
              removedSkills.push(`${plugin.name}/${s}`)
              return false
            }
            return true
          })
          return { ...plugin, enabledSkills: validSkills }
        })
        .filter((p) => Array.isReadonlyArrayNonEmpty(p.enabledSkills))

      for (const removed of removedSkills) {
        yield* Effect.log(`  Removed: ${removed} (no longer exists)`)
      }

      if (Array.isArrayNonEmpty(updatedPlugins)) {
        updatedRepos.push({ ...repo, plugins: updatedPlugins })
      }

      const existingLinks = yield* Symlink.listSkillLinks(agentsDir)
      const expectedSkills = new Set(updatedPlugins.flatMap((p) => p.enabledSkills))

      for (const link of existingLinks) {
        if (!expectedSkills.has(link)) {
          yield* Symlink.removeSkillLink(agentsDir, lockFile.skillDirs, link)
        }
      }

      for (const skill of availableSkills) {
        if (expectedSkills.has(skill.skillName)) {
          yield* Symlink.createSkillLink(agentsDir, lockFile.skillDirs, skill.skillName, skill.skillPath)
        }
      }
    }

    const newLockFile: LockFile = {
      ...lockFile,
      repositories: updatedRepos,
    }
    yield* LockFileService.write(agentsDir, newLockFile)
    yield* GitIgnore.write(agentsDir)

    yield* Effect.log('Sync complete.')
  })
