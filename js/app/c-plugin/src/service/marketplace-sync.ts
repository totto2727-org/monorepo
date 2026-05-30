import { Effect, FileSystem, Schema, String } from 'effect'

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

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- input is unknown (file content)
const decodeClaudeCursor = Schema.decodeUnknownEffect(Marketplace)
// oxlint-disable-next-line rules/prefer-non-unknown-decode -- input is unknown (file content)
const decodeCodex = Schema.decodeUnknownEffect(CodexMarketplace)

const readBaseMarketplace = (
  repoDir: string,
  baseKind: MarketplaceKind,
): Effect.Effect<ParsedMarketplace, Error, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const config = getKindConfig(baseKind)
    const marketplacePath = `${repoDir}/${config.marketplacePath}`
    const raw = yield* fs
      .readFileString(marketplacePath)
      .pipe(Effect.mapError(() => new Error(`marketplace.json not found at ${marketplacePath}`)))
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
          source: p.source.path.replace(/^\.\//u, ''),
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

const writeJson = (filePath: string, data: unknown): Effect.Effect<void, never, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    yield* fs.makeDirectory(filePath.slice(0, filePath.lastIndexOf('/')), { recursive: true }).pipe(Effect.ignore)
    yield* fs.writeFileString(filePath, `${JSON.stringify(data, null, 2)}\n`).pipe(Effect.ignore)
  })

const syncPluginJson = (
  repoDir: string,
  baseKind: MarketplaceKind,
  targetKind: MarketplaceKind,
  pluginSource: string,
): Effect.Effect<void, never, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const baseConfig = getKindConfig(baseKind)
    const targetConfig = getKindConfig(targetKind)
    const basePluginJsonPath = `${repoDir}/${pluginSource}/${baseConfig.configDir}/plugin.json`
    const targetPluginJsonPath = `${repoDir}/${pluginSource}/${targetConfig.configDir}/plugin.json`

    const raw = yield* fs.readFileString(basePluginJsonPath).pipe(Effect.orElseSucceed(() => ''))

    if (String.isNonEmpty(raw)) {
      const parsed = parseJson(raw)
      yield* writeJson(targetPluginJsonPath, parsed)
    }
  })

export const syncMarketplace = (
  repoDir: string,
  baseKind: MarketplaceKind,
): Effect.Effect<void, Error, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const marketplace = yield* readBaseMarketplace(repoDir, baseKind)
    const targetKinds = allKinds.filter((k) => k !== baseKind)

    for (const targetKind of targetKinds) {
      const targetConfig = getKindConfig(targetKind)
      const targetMarketplacePath = `${repoDir}/${targetConfig.marketplacePath}`

      yield* Effect.log(`Generating ${targetKind} marketplace...`)
      const formatted = formatForKind(marketplace, targetKind)
      yield* writeJson(targetMarketplacePath, formatted)

      for (const plugin of marketplace.plugins) {
        yield* syncPluginJson(repoDir, baseKind, targetKind, plugin.source)
      }
    }

    yield* Effect.log('Marketplace sync complete.')
  })
