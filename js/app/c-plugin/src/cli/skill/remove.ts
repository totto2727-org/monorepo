import { Array, Effect } from 'effect'
import { Command, Flag, Prompt } from 'effect/unstable/cli'

import { getAgentsDir } from '#@/lib/paths.ts'
import type { LockFile } from '#@/schema/lock-file.ts'
import * as Cache from '#@/service/cache.ts'
import * as LockFileService from '#@/service/lock-file.ts'
import * as Symlink from '#@/service/symlink.ts'

export const removeRepoCaches = (agentsDir: string, lockFile: LockFile, removedRepoSources: ReadonlySet<string>) =>
  Effect.gen(function* () {
    for (const source of removedRepoSources) {
      const repo = lockFile.repositories.find((r) => r.source === source)
      if (repo?.sourceType === 'local') {
        continue
      }
      yield* Effect.log(`Removing cache for ${source}...`)
      yield* Cache.removeRepo(agentsDir, source)
    }
  })

export const removeCommand = Command.make(
  'remove',
  {
    global: Flag.boolean('global').pipe(Flag.withAlias('g')),
  },
  (config) =>
    Effect.gen(function* () {
      const agentsDir = getAgentsDir(config.global)
      const lockFile = yield* LockFileService.read(agentsDir)

      const allSkills = lockFile.repositories.flatMap((repo) =>
        repo.plugins.flatMap((plugin) =>
          plugin.enabledSkills.map((skillName) => ({
            pluginName: plugin.name,
            repoSource: repo.source,
            skillName,
          })),
        ),
      )

      if (Array.isArrayEmpty(allSkills)) {
        yield* Effect.log('No skills installed.')
        return
      }

      const choices = allSkills.map((s) => ({
        title: `${s.repoSource} > ${s.pluginName}/${s.skillName}`,
        value: s,
      }))

      const toRemove = yield* Prompt.multiSelect({
        choices,
        message: 'Select skills to remove:',
      })

      if (Array.isReadonlyArrayEmpty(toRemove)) {
        yield* Effect.log('No skills selected for removal.')
        return
      }

      const removeSet = new Set(toRemove.map((s) => `${s.repoSource}/${s.pluginName}/${s.skillName}`))

      const updatedRepos = lockFile.repositories
        .map((repo) => ({
          ...repo,
          plugins: repo.plugins
            .map((plugin) => ({
              ...plugin,
              enabledSkills: plugin.enabledSkills.filter((s) => !removeSet.has(`${repo.source}/${plugin.name}/${s}`)),
            }))
            .filter((p) => Array.isArrayNonEmpty(p.enabledSkills)),
        }))
        .filter((r) => Array.isArrayNonEmpty(r.plugins))

      const removedRepoSources = new Set(
        lockFile.repositories.filter((r) => !updatedRepos.some((ur) => ur.source === r.source)).map((r) => r.source),
      )

      const newLockFile: LockFile = {
        ...lockFile,
        repositories: updatedRepos,
      }
      yield* LockFileService.write(agentsDir, newLockFile)

      for (const skill of toRemove) {
        yield* Symlink.removeSkillLink(agentsDir, lockFile.skillDirs, skill.skillName)
      }

      yield* removeRepoCaches(agentsDir, lockFile, removedRepoSources)

      yield* Effect.log(`Removed ${toRemove.length} skill(s).`)
    }),
).pipe(Command.withDescription('Remove installed skills'))
