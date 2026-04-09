import type { Dirent } from 'node:fs'
import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { Effect, Schema } from 'effect'

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
            source: p.source.path.replace(/^\.\//, ''),
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

const resolvePluginSkills = (repoDir: string, plugin: NormalizedPlugin): Effect.Effect<ResolvedSkill[], Error> =>
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

export const resolveFromRepo = (
  repoDir: string,
  kind: MarketplaceKind,
): Effect.Effect<readonly ResolvedSkill[], Error> =>
  Effect.gen(function* () {
    const config = getKindConfig(kind)
    const marketplacePath = NodePath.join(repoDir, config.marketplacePath)
    const raw = yield* Effect.tryPromise({
      catch: () => new Error(`marketplace.json not found at ${marketplacePath}`),
      try: () => Fs.readFile(marketplacePath, 'utf-8'),
    })
    const plugins = yield* parseMarketplace(parseJson(raw), kind, marketplacePath)

    const results: ResolvedSkill[] = []
    for (const plugin of plugins) {
      const pluginSkills = yield* resolvePluginSkills(repoDir, plugin)
      results.push(...pluginSkills)
    }

    return results
  })

export const detectAvailableKinds = (repoDir: string): Effect.Effect<readonly MarketplaceKind[]> =>
  Effect.gen(function* () {
    const available: MarketplaceKind[] = []
    for (const kind of allKinds) {
      const config = getKindConfig(kind)
      const marketplacePath = NodePath.join(repoDir, config.marketplacePath)
      const exists: boolean = yield* Effect.tryPromise({
        catch: () => new Error('access failed'),
        try: async () => {
          await Fs.access(marketplacePath)
          return true
        },
      }).pipe(Effect.orElseSucceed(() => false))
      if (exists) {
        available.push(kind)
      }
    }
    return available
  })
