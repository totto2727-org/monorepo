import type { Dirent } from 'node:fs'
import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { Effect, Schema } from 'effect'

import { parseJson } from '#@/lib/json.ts'
import { Marketplace } from '#@/schema/marketplace.ts'
import type { MarketplacePlugin } from '#@/schema/marketplace.ts'

export interface ResolvedSkill {
  readonly pluginName: string
  readonly pluginPath: string
  readonly skillName: string
  readonly skillPath: string
}

const decode = Schema.decodeUnknownEffect(Marketplace)

const resolvePluginSkills = (repoDir: string, plugin: MarketplacePlugin): Effect.Effect<ResolvedSkill[], Error> =>
  Effect.gen(function* () {
    const pluginDir = NodePath.resolve(repoDir, plugin.source)
    const skillsDir = NodePath.join(pluginDir, 'skills')
    const entries: Dirent[] = yield* Effect.tryPromise({
      catch: () => new Error(`Cannot read skills directory: ${skillsDir}`),
      try: () => Fs.readdir(skillsDir, { withFileTypes: true }),
    }).pipe(Effect.orElseSucceed((): Dirent[] => []))

    const skills: ResolvedSkill[] = []

    for (const entry of entries) {
      if (!entry.isDirectory()) {
        continue
      }
      const skillMdPath = NodePath.join(skillsDir, entry.name, 'SKILL.md')
      const exists: boolean = yield* Effect.tryPromise({
        catch: () => new Error('access failed'),
        try: async () => {
          await Fs.access(skillMdPath)
          return true
        },
      }).pipe(Effect.orElseSucceed(() => false))
      if (exists) {
        skills.push({
          pluginName: plugin.name,
          pluginPath: plugin.source,
          skillName: entry.name,
          skillPath: NodePath.join(skillsDir, entry.name),
        })
      }
    }

    return skills
  })

export const resolveFromRepo = (repoDir: string): Effect.Effect<readonly ResolvedSkill[], Error> =>
  Effect.gen(function* () {
    const marketplacePath = NodePath.join(repoDir, '.claude-plugin', 'marketplace.json')
    const raw = yield* Effect.tryPromise({
      catch: () => new Error(`marketplace.json not found at ${marketplacePath}`),
      try: () => Fs.readFile(marketplacePath, 'utf8'),
    })
    const marketplace = yield* decode(parseJson(raw)).pipe(
      Effect.mapError(() => new Error(`Invalid marketplace.json at ${marketplacePath}`)),
    )

    const results: ResolvedSkill[] = []
    for (const plugin of marketplace.plugins) {
      const pluginSkills = yield* resolvePluginSkills(repoDir, plugin)
      results.push(...pluginSkills)
    }

    return results
  })
