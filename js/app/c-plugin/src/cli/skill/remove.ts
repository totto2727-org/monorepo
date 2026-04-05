import { Effect } from 'effect'
import { Command, Flag, Prompt } from 'effect/unstable/cli'

import { getAgentsDir } from '#@/lib/paths.ts'
import type { LockFile } from '#@/schema/lock-file.ts'
import * as Cache from '#@/service/cache.ts'
import * as LockFileService from '#@/service/lock-file.ts'
import * as Symlink from '#@/service/symlink.ts'

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

      if (allSkills.length === 0) {
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

      if (toRemove.length === 0) {
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
            .filter((p) => p.enabledSkills.length > 0),
        }))
        .filter((r) => r.plugins.length > 0)

      const removedRepoSources = new Set(
        lockFile.repositories.filter((r) => !updatedRepos.some((ur) => ur.source === r.source)).map((r) => r.source),
      )

      const newLockFile: LockFile = {
        repositories: updatedRepos,
        version: 1,
      }
      yield* LockFileService.write(agentsDir, newLockFile)

      for (const skill of toRemove) {
        yield* Symlink.removeSkillLink(agentsDir, skill.skillName)
      }

      for (const source of removedRepoSources) {
        yield* Effect.log(`Removing cache for ${source}...`)
        yield* Cache.removeRepo(agentsDir, source)
      }

      yield* Effect.log(`Removed ${toRemove.length} skill(s).`)
    }),
).pipe(Command.withDescription('Remove installed skills'))
