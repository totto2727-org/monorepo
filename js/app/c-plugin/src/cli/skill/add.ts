import { Array, Effect, FileSystem, Option, Path } from 'effect'
import { Argument, Command, Flag, Prompt } from 'effect/unstable/cli'

import {
  findNearestAgentsDir,
  getGlobalAgentsDir,
  hasLocalPathPrefix,
  normalizePathSpec,
  toRelativeLocalPath,
} from '#@/lib/paths.ts'
import { hasSupportedPluginFormat } from '#@/lib/plugin-format.ts'
import type { LockFile, PluginEntry, RepositoryEntry } from '#@/schema/lock-file.ts'
import type { MarketplaceKind } from '#@/schema/marketplace-kind.ts'
import * as Cache from '#@/service/cache.ts'
import * as Git from '#@/service/git.ts'
import * as LockFileService from '#@/service/lock-file.ts'
import * as SkillResolver from '#@/service/skill-resolver.ts'
import * as SyncService from '#@/service/sync.ts'

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

type ResolvedSource =
  | { readonly type: 'github'; readonly source: string; readonly dir: string; readonly commitHash: string }
  | { readonly type: 'local'; readonly source: string; readonly dir: string }

export const addCommand = Command.make(
  'add',
  {
    global: Flag.boolean('global').pipe(Flag.withAlias('g')),
    local: Flag.string('local').pipe(Flag.optional),
    repo: Argument.string('repo').pipe(Argument.optional),
  },
  (config) =>
    Effect.gen(function* () {
      const path = yield* Path.Path
      const agentsDir = yield* config.global ? Effect.succeed(getGlobalAgentsDir()) : findNearestAgentsDir()
      const agentsRoot = path.dirname(agentsDir)
      yield* Cache.ensureDirs(agentsDir, agentsRoot)

      const resolved: ResolvedSource = yield* Option.match(config.local, {
        onNone: () =>
          Effect.gen(function* () {
            const repoSpec = yield* Option.match(config.repo, {
              onNone: () => Effect.fail(new Error('Either <repo> or --local <path> must be provided')),
              onSome: (value) => Effect.succeed(value),
            })
            yield* Git.checkInstalled
            yield* Effect.log(`Cloning ${repoSpec}...`)
            const repoDir = yield* Cache.ensureRepo(agentsRoot, repoSpec)
            const commitHash = yield* Git.revParseHead(repoDir)
            return { commitHash, dir: repoDir, source: repoSpec, type: 'github' as const }
          }),
        onSome: (rawSpec) =>
          Effect.gen(function* () {
            const localSpec = normalizePathSpec(rawSpec)
            if (!hasLocalPathPrefix(localSpec)) {
              return yield* Effect.fail(new Error(`Invalid local path: ${rawSpec}. Expected './...' (local path).`))
            }

            const resolvedAbs = path.resolve(process.cwd(), localSpec)
            const fs = yield* FileSystem.FileSystem
            const exists = yield* fs.exists(resolvedAbs).pipe(Effect.orElseSucceed(() => false))
            if (!exists) {
              return yield* Effect.fail(new Error(`Local path does not exist: ${localSpec}`))
            }

            const hasFormat = yield* hasSupportedPluginFormat(resolvedAbs)
            if (!hasFormat) {
              return yield* Effect.fail(new Error(`No marketplace found at: ${localSpec}`))
            }

            const relativeSource = toRelativeLocalPath(resolvedAbs, agentsRoot)
            return { dir: resolvedAbs, source: relativeSource, type: 'local' as const }
          }),
      })

      const availableKinds = yield* SkillResolver.detectAvailableKinds(resolved.dir)
      if (Array.isReadonlyArrayEmpty(availableKinds)) {
        yield* Effect.log('No marketplace found in this repository.')
        return
      }

      const selectedKind: MarketplaceKind =
        availableKinds.length === 1
          ? (() => {
              const [first] = availableKinds
              return first ?? 'claude'
            })()
          : yield* Prompt.select({
              choices: availableKinds.map((k) => ({ title: k, value: k })),
              message: 'Multiple marketplace kinds found. Select one:',
            })
      if (availableKinds.length === 1) {
        yield* Effect.log(`Using marketplace kind: ${selectedKind}`)
      }

      const allSkills = yield* SkillResolver.resolveFromRepo(resolved.dir, selectedKind)
      if (Array.isReadonlyArrayEmpty(allSkills)) {
        yield* Effect.log('No skills found in this repository.')
        return
      }

      const lockFile = yield* LockFileService.read(agentsDir)
      const existingRepo = lockFile.repositories.find((r) => r.source === resolved.source)
      const alreadyEnabled = new Set(
        (existingRepo?.plugins ?? []).flatMap((p) => p.enabledSkills.map((skill) => `${p.name}/${skill}`)),
      )

      const choices = allSkills.map((s) => {
        const key = `${s.pluginName}/${s.skillName}`
        return {
          selected: alreadyEnabled.has(key),
          title: key,
          value: s,
        }
      })

      const selected = yield* Prompt.multiSelect({
        choices,
        message: 'Select skills to install:',
      })

      if (Array.isReadonlyArrayEmpty(selected)) {
        yield* Effect.log('No skills selected.')
        return
      }

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

      const mergedPlugins = mergePlugins(existingRepo?.plugins ?? [], [...pluginMap.values()])
      const newRepoEntry: RepositoryEntry =
        resolved.type === 'github'
          ? {
              commitHash: resolved.commitHash,
              marketplaceKind: selectedKind,
              plugins: mergedPlugins,
              source: resolved.source,
              sourceType: 'github',
            }
          : {
              marketplaceKind: selectedKind,
              plugins: mergedPlugins,
              source: resolved.source,
              sourceType: 'local',
            }

      const newLockFile: LockFile = {
        ...lockFile,
        repositories: [...lockFile.repositories.filter((r) => r.source !== resolved.source), newRepoEntry],
      }

      yield* LockFileService.write(agentsDir, newLockFile)
      yield* SyncService.run(agentsDir)
    }),
).pipe(Command.withDescription('Add skills from a plugin repository'))
