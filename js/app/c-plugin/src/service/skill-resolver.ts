import { Effect, FileSystem, Schema } from 'effect'

import { parseJson } from '#@/lib/json.ts'
import type { MarketplaceKind } from '#@/schema/marketplace-kind.ts'
import { allKinds, getKindConfig } from '#@/schema/marketplace-kind.ts'
import { CodexMarketplace, Marketplace } from '#@/schema/marketplace.ts'
import type { NormalizedPlugin } from '#@/schema/marketplace.ts'

export interface ResolvedSkill {
  readonly pluginName: string
  readonly pluginPath: string
  readonly skillName: string
  readonly skillPath: string
}

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- input is unknown (file content)
const decodeClaudeCursor = Schema.decodeUnknownEffect(Marketplace)
// oxlint-disable-next-line rules/prefer-non-unknown-decode -- input is unknown (file content)
const decodeCodex = Schema.decodeUnknownEffect(CodexMarketplace)

const parseMarketplace = (
  raw: unknown,
  kind: MarketplaceKind,
  path: string,
): Effect.Effect<readonly NormalizedPlugin[], Error> =>
  kind === 'codex'
    ? decodeCodex(raw).pipe(
        Effect.map((m) =>
          m.plugins.map((p) => ({
            description: p.description,
            name: p.name,
            source: p.source.path.replace(/^\.\//u, ''),
          })),
        ),
        Effect.mapError(() => new Error(`Invalid Codex marketplace.json at ${path}`)),
      )
    : decodeClaudeCursor(raw).pipe(
        Effect.map((m) =>
          m.plugins.map((p) => ({
            description: p.description,
            name: p.name,
            source: p.source,
          })),
        ),
        Effect.mapError(() => new Error(`Invalid marketplace.json at ${path}`)),
      )

const resolvePluginSkills = (
  repoDir: string,
  plugin: NormalizedPlugin,
): Effect.Effect<ResolvedSkill[], Error, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const pluginDir = `${repoDir}/${plugin.source}`
    const skillsDir = `${pluginDir}/skills`
    const entries = yield* fs.readDirectory(skillsDir).pipe(Effect.orElseSucceed(() => [] as readonly string[]))

    const skills: ResolvedSkill[] = []

    for (const entry of entries) {
      const skillPath = `${skillsDir}/${entry}`
      const stat = yield* fs.stat(skillPath).pipe(Effect.orElseSucceed(() => null))
      if (stat?.type !== 'Directory') {
        continue
      }
      const skillMdPath = `${skillPath}/SKILL.md`
      const exists = yield* fs.exists(skillMdPath).pipe(Effect.orElseSucceed(() => false))
      if (exists) {
        skills.push({
          pluginName: plugin.name,
          pluginPath: plugin.source,
          skillName: entry,
          skillPath,
        })
      }
    }

    return skills
  })

export const resolveFromRepo = (
  repoDir: string,
  kind: MarketplaceKind,
): Effect.Effect<readonly ResolvedSkill[], Error, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const config = getKindConfig(kind)
    const marketplacePath = `${repoDir}/${config.marketplacePath}`
    const raw = yield* fs
      .readFileString(marketplacePath)
      .pipe(Effect.mapError(() => new Error(`marketplace.json not found at ${marketplacePath}`)))
    const plugins = yield* parseMarketplace(parseJson(raw), kind, marketplacePath)

    const results: ResolvedSkill[] = []
    for (const plugin of plugins) {
      const pluginSkills = yield* resolvePluginSkills(repoDir, plugin)
      results.push(...pluginSkills)
    }

    return results
  })

export const detectAvailableKinds = (
  repoDir: string,
): Effect.Effect<readonly MarketplaceKind[], never, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const available: MarketplaceKind[] = []
    for (const kind of allKinds) {
      const config = getKindConfig(kind)
      const marketplacePath = `${repoDir}/${config.marketplacePath}`
      const exists = yield* fs.exists(marketplacePath).pipe(Effect.orElseSucceed(() => false))
      if (exists) {
        available.push(kind)
      }
    }
    return available
  })
