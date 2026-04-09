import { Effect } from 'effect'

import type { LockFile } from '#@/schema/lock-file.ts'
import * as Cache from '#@/service/cache.ts'
import * as Git from '#@/service/git.ts'
import * as LockFileService from '#@/service/lock-file.ts'
import * as SkillResolver from '#@/service/skill-resolver.ts'
import * as Symlink from '#@/service/symlink.ts'

export const run = (
  agentsDir: string,
): Effect.Effect<void, Error | Git.GitError | LockFileService.LockFileCorruptError> =>
  Effect.gen(function* () {
    yield* Git.checkInstalled
    yield* Cache.ensureDirs(agentsDir)

    const lockFile = yield* LockFileService.read(agentsDir)
    if (lockFile.repositories.length === 0) {
      yield* Effect.log('No repositories in lock file.')
      return
    }

    const updatedRepos: LockFile['repositories'][number][] = []

    for (const repo of lockFile.repositories) {
      yield* Effect.log(`Syncing ${repo.source}...`)
      const repoDir = yield* Cache.ensureRepo(agentsDir, repo.source)
      yield* Git.checkout(repoDir, repo.commitHash)

      const availableSkills = yield* SkillResolver.resolveFromRepo(repoDir)
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
        .filter((p) => p.enabledSkills.length > 0)

      for (const removed of removedSkills) {
        yield* Effect.log(`  Removed: ${removed} (no longer exists)`)
      }

      if (updatedPlugins.length > 0) {
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

    yield* Effect.log('Sync complete.')
  })
