import { Effect } from 'effect'
import { Argument, Command, Flag, Prompt } from 'effect/unstable/cli'

import { getAgentsDir } from '#@/lib/paths.ts'
import type { LockFile, PluginEntry, RepositoryEntry } from '#@/schema/lock-file.ts'
import * as Cache from '#@/service/cache.ts'
import * as Git from '#@/service/git.ts'
import * as LockFileService from '#@/service/lock-file.ts'
import * as SkillResolver from '#@/service/skill-resolver.ts'
import * as Symlink from '#@/service/symlink.ts'

const mergePlugins = (existing: readonly PluginEntry[], incoming: readonly PluginEntry[]): PluginEntry[] => {
  const map = new Map<string, PluginEntry>()
  for (const p of existing) {
    map.set(p.name, p)
  }
  for (const p of incoming) {
    const prev = map.get(p.name)
    if (prev) {
      const skills = [...new Set([...prev.enabledSkills, ...p.enabledSkills])]
      map.set(p.name, { ...prev, enabledSkills: skills })
    } else {
      map.set(p.name, p)
    }
  }
  return [...map.values()]
}

export const addCommand = Command.make(
  'add',
  {
    global: Flag.boolean('global').pipe(Flag.withAlias('g')),
    repo: Argument.string('repo'),
  },
  (config) =>
    Effect.gen(function* () {
      yield* Git.checkInstalled

      const agentsDir = getAgentsDir(config.global)
      yield* Cache.ensureDirs(agentsDir)

      yield* Effect.log(`Cloning ${config.repo}...`)
      const repoDir = yield* Cache.ensureRepo(agentsDir, config.repo)
      const commitHash = yield* Git.revParseHead(repoDir)

      const allSkills = yield* SkillResolver.resolveFromRepo(repoDir)
      if (allSkills.length === 0) {
        yield* Effect.log('No skills found in this repository.')
        return
      }

      const choices = allSkills.map((s) => ({
        title: `${s.pluginName}/${s.skillName}`,
        value: s,
      }))

      const selected = yield* Prompt.multiSelect({
        choices,
        message: 'Select skills to install:',
      })

      if (selected.length === 0) {
        yield* Effect.log('No skills selected.')
        return
      }

      const lockFile = yield* LockFileService.read(agentsDir)

      const pluginMap = new Map<string, PluginEntry>()
      for (const skill of selected) {
        const key = skill.pluginName
        const existing = pluginMap.get(key)
        if (existing) {
          pluginMap.set(key, {
            ...existing,
            enabledSkills: [...existing.enabledSkills, skill.skillName],
          })
        } else {
          pluginMap.set(key, {
            enabledSkills: [skill.skillName],
            name: skill.pluginName,
            path: skill.pluginPath,
          })
        }
      }

      const existingRepo = lockFile.repositories.find((r) => r.source === config.repo)
      const newRepoEntry: RepositoryEntry = {
        commitHash,
        plugins: mergePlugins(existingRepo?.plugins ?? [], [...pluginMap.values()]),
        source: config.repo,
        sourceType: 'github',
      }

      const newLockFile: LockFile = {
        repositories: [...lockFile.repositories.filter((r) => r.source !== config.repo), newRepoEntry],
        version: 1,
      }

      yield* LockFileService.write(agentsDir, newLockFile)

      for (const skill of selected) {
        yield* Symlink.createSkillLink(agentsDir, skill.skillName, skill.skillPath)
      }

      yield* Effect.log(`Installed ${selected.length} skill(s).`)
    }),
).pipe(Command.withDescription('Add skills from a plugin repository'))
