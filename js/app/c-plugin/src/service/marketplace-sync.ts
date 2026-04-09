import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { Effect, Schema } from 'effect'

import { parseJson } from '#@/lib/json.ts'
import type { MarketplaceKind } from '#@/schema/marketplace-kind.ts'
import { allKinds, getKindConfig } from '#@/schema/marketplace-kind.ts'
import { CodexMarketplace, Marketplace } from '#@/schema/marketplace.ts'
import type { NormalizedPlugin } from '#@/schema/marketplace.ts'

interface ParsedMarketplace {
  readonly name: string
  readonly plugins: readonly NormalizedPlugin[]
  readonly raw: unknown
}

// eslint-disable-next-line rules/prefer-non-unknown-decode -- input is unknown (file content)
const decodeClaudeCursor = Schema.decodeUnknownEffect(Marketplace)
// eslint-disable-next-line rules/prefer-non-unknown-decode -- input is unknown (file content)
const decodeCodex = Schema.decodeUnknownEffect(CodexMarketplace)

const readBaseMarketplace = (repoDir: string, baseKind: MarketplaceKind): Effect.Effect<ParsedMarketplace, Error> =>
  Effect.gen(function* () {
    const config = getKindConfig(baseKind)
    const marketplacePath = NodePath.join(repoDir, config.marketplacePath)
    const raw = yield* Effect.tryPromise({
      catch: () => new Error(`marketplace.json not found at ${marketplacePath}`),
      try: () => Fs.readFile(marketplacePath, 'utf-8'),
    })
    const parsed = parseJson(raw)

    if (baseKind === 'codex') {
      const marketplace = yield* decodeCodex(parsed).pipe(
        Effect.mapError(() => new Error(`Invalid Codex marketplace.json at ${marketplacePath}`)),
      )
      return {
        name: marketplace.name,
        plugins: marketplace.plugins.map((p) => ({
          description: p.description,
          name: p.name,
          source: p.source.path.replace(/^\.\//, ''),
        })),
        raw: parsed,
      }
    }

    const marketplace = yield* decodeClaudeCursor(parsed).pipe(
      Effect.mapError(() => new Error(`Invalid marketplace.json at ${marketplacePath}`)),
    )
    return {
      name: marketplace.name,
      plugins: marketplace.plugins.map((p) => ({
        description: p.description,
        name: p.name,
        source: p.source,
      })),
      raw: parsed,
    }
  })

const toClaudeCursorFormat = (marketplace: ParsedMarketplace): unknown => ({
  name: marketplace.name,
  plugins: marketplace.plugins.map((p) => ({
    description: p.description,
    name: p.name,
    source: p.source,
  })),
})

const toCodexFormat = (marketplace: ParsedMarketplace): unknown => ({
  name: marketplace.name,
  plugins: marketplace.plugins.map((p) => ({
    category: 'Productivity',
    name: p.name,
    policy: { authentication: 'ON_INSTALL', installation: 'AVAILABLE' },
    source: { path: `./${p.source}`, source: 'local' },
  })),
})

const formatForKind = (marketplace: ParsedMarketplace, targetKind: MarketplaceKind): unknown =>
  targetKind === 'codex' ? toCodexFormat(marketplace) : toClaudeCursorFormat(marketplace)

const writeJson = (filePath: string, data: unknown): Effect.Effect<void> =>
  Effect.tryPromise({
    catch: (e: unknown) => e,
    try: async () => {
      await Fs.mkdir(NodePath.dirname(filePath), { recursive: true })
      await Fs.writeFile(filePath, `${JSON.stringify(data, null, 2)}\n`, 'utf-8')
    },
  }).pipe(Effect.ignore)

const syncPluginJson = (
  repoDir: string,
  baseKind: MarketplaceKind,
  targetKind: MarketplaceKind,
  pluginSource: string,
): Effect.Effect<void> =>
  Effect.gen(function* () {
    const baseConfig = getKindConfig(baseKind)
    const targetConfig = getKindConfig(targetKind)
    const basePluginJsonPath = NodePath.join(repoDir, pluginSource, baseConfig.configDir, 'plugin.json')
    const targetPluginJsonPath = NodePath.join(repoDir, pluginSource, targetConfig.configDir, 'plugin.json')

    const raw = yield* Effect.tryPromise({
      catch: () => new Error(`plugin.json not found at ${basePluginJsonPath}`),
      try: () => Fs.readFile(basePluginJsonPath, 'utf-8'),
    }).pipe(Effect.orElseSucceed(() => ''))

    if (raw.length > 0) {
      const parsed = parseJson(raw)
      yield* writeJson(targetPluginJsonPath, parsed)
    }
  })

export const syncMarketplace = (repoDir: string, baseKind: MarketplaceKind): Effect.Effect<void, Error> =>
  Effect.gen(function* () {
    const marketplace = yield* readBaseMarketplace(repoDir, baseKind)
    const targetKinds = allKinds.filter((k) => k !== baseKind)

    for (const targetKind of targetKinds) {
      const targetConfig = getKindConfig(targetKind)
      const targetMarketplacePath = NodePath.join(repoDir, targetConfig.marketplacePath)

      yield* Effect.log(`Generating ${targetKind} marketplace...`)
      const formatted = formatForKind(marketplace, targetKind)
      yield* writeJson(targetMarketplacePath, formatted)

      for (const plugin of marketplace.plugins) {
        yield* syncPluginJson(repoDir, baseKind, targetKind, plugin.source)
      }
    }

    yield* Effect.log('Marketplace sync complete.')
  })
