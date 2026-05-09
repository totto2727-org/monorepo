#!/usr/bin/env node
/**
 * Fetches model data from models.dev and generates Factory settings.json fragments.
 *
 * Usage:
 *   vp node src/bin.ts             # print JSON to stdout (dry-run)
 *   vp node src/bin.ts --write     # update ~/.factory/settings.json in place
 */

import { access, readFile, writeFile } from 'node:fs/promises'
import { homedir } from 'node:os'

import { Array as EffectArray, Predicate, Schema } from 'effect'

const MODELS_DEV_URL = 'https://models.dev/api.json'
const SETTINGS_PATH = `${homedir()}/.factory/settings.json`

// ── Anthropic (Meridian) ──────────────────────────────────────────────────────
const ANTHROPIC_MODELS = ['claude-opus-4-7', 'claude-sonnet-4-6', 'claude-haiku-4-5'] as const

const ANTHROPIC_OVERRIDES = {
  apiKey: 'x',
  baseUrl: 'http://127.0.0.1:3456',
  noImageSupport: false,
  provider: 'anthropic' as const,
}

// ── opencode-go ──────────────────────────────────────────────────────────────
const OPENCODE_GO_OVERRIDES = {
  apiKey: `\${OPENCODE_ZEN_API_KEY}`,
  baseUrl: 'https://opencode.ai/zen/go/v1',
  provider: 'generic-chat-completion-api' as const,
}

// ── Z.AI Coding Plan (hardcoded, to be removed later) ───────────────────────
const ZAI_OVERRIDES = {
  apiKey: `\${Z_AI_API_KEY}`,
  baseUrl: 'https://api.z.ai/api/coding/paas/v4',
  maxOutputTokens: 131_072,
  noImageSupport: true,
  provider: 'generic-chat-completion-api' as const,
}

const ZAI_MODELS = [
  { context: 200_000, displayName: 'GLM-5.1', model: 'glm-5.1' },
  { context: 204_800, displayName: 'GLM-4.7', model: 'glm-4.7' },
  { context: 200_000, displayName: 'GLM-4.7-Flash', model: 'glm-4.7-flash' },
  { context: 200_000, displayName: 'GLM-4.7-FlashX', model: 'glm-4.7-flashx' },
]

// ── Helpers ──────────────────────────────────────────────────────────────────

const LOWER_WORDS = new Set(['v2', 'v4', 'flash', 'flashx', 'plus', 'pro', 'omni'])

const displayName = (modelId: string): string => {
  const parts = modelId.split('-')
  const first = parts.at(0)
  if (Predicate.isNullish(first)) {
    return ''
  }

  const merged: string[] = [first]
  for (const [current, prev] of EffectArray.zip(parts.slice(1), parts)) {
    const last = merged.at(-1)
    if (Predicate.isNullish(last)) {
      continue
    }
    if (/^\d$/.test(prev) && /^\d$/.test(current)) {
      merged.pop()
      merged.push(`${last}.${current}`)
    } else {
      merged.push(current)
    }
  }

  return merged
    .map((p) => {
      // version numbers like "4.7", "2.5"
      if (/^\d/.test(p)) {
        return p
      }
      if (LOWER_WORDS.has(p)) {
        return p
      }
      return p.charAt(0).toUpperCase() + p.slice(1)
    })
    .join(' ')
}

const slugForId = (modelId: string): string => modelId.replaceAll('.', '-')

const computeCompactionLimit = (context: number, maxOutput: number): number => {
  const usable = context - maxOutput
  const buffer = Math.max(4000, Math.round(usable * 0.05))
  return Math.max(0, usable - buffer)
}

// ── Schemas ──────────────────────────────────────────────────────────────────

const LimitSchema = Schema.Struct({
  context: Schema.Number,
  output: Schema.Number,
})

const AnthropicModelSchema = Schema.Struct({
  limit: LimitSchema,
})

const OpencodeGoModelSchema = Schema.Struct({
  attachment: Schema.Boolean,
  limit: LimitSchema,
  name: Schema.String,
})

const ProviderSchema = Schema.Record(
  Schema.String,
  Schema.Struct({
    models: Schema.Record(Schema.String, Schema.Unknown),
  }),
)

// ── Build entries ────────────────────────────────────────────────────────────

const buildAnthropicEntries = (
  providerData: Record<string, { models: Record<string, unknown> }>,
): { compaction: number; entry: { id: string } & Record<string, unknown> }[] => {
  const { anthropic } = providerData
  if (Predicate.isNullish(anthropic)) {
    throw new Error('anthropic provider not found in models.dev')
  }

  return ANTHROPIC_MODELS.map((modelId) => {
    const rawModel = anthropic.models[modelId]
    if (Predicate.isNullish(rawModel)) {
      throw new Error(`Model ${modelId} not found in anthropic provider`)
    }
    // oxlint-disable-next-line rules/no-sync-decode
    const model = Schema.decodeUnknownSync(AnthropicModelSchema)(rawModel)

    const maxOutput = model.limit.output
    const { context } = model.limit
    const shortName = modelId.replace('claude-', '')
    const name = displayName(shortName)

    return {
      compaction: computeCompactionLimit(context, maxOutput),
      entry: {
        ...ANTHROPIC_OVERRIDES,
        displayName: `Claude ${name} - Meridian`,
        id: `custom:${modelId}-meridian`,
        index: 0,
        maxOutputTokens: maxOutput,
        model: modelId,
      },
    }
  })
}

const extractProviderPrefix = (modelId: string): string => {
  const match = /^[a-z]+/.exec(modelId)
  if (Predicate.isNullish(match)) {
    return modelId
  }
  return match[0]
}

const buildOpencodeGoEntries = (
  providerData: Record<string, { models: Record<string, unknown> }>,
): { compaction: number; entry: { id: string } & Record<string, unknown> }[] => {
  const ocg = providerData['opencode-go']
  if (Predicate.isNullish(ocg)) {
    throw new Error('opencode-go provider not found in models.dev')
  }

  return Object.entries(ocg.models)
    .toSorted(([a], [b]) => {
      const pa = extractProviderPrefix(a)
      const pb = extractProviderPrefix(b)
      return pa === pb ? 0 : pa.localeCompare(pb)
    })
    .map(([modelId, rawModel]) => {
      // oxlint-disable-next-line rules/no-sync-decode
      const m = Schema.decodeUnknownSync(OpencodeGoModelSchema)(rawModel)
      const maxOutput = m.limit.output
      const { context } = m.limit
      const slug = slugForId(modelId)

      return {
        compaction: computeCompactionLimit(context, maxOutput),
        entry: {
          ...OPENCODE_GO_OVERRIDES,
          displayName: `${m.name} - OpenCode Go`,
          id: `custom:${slug}-opencode-go`,
          index: 0,
          maxOutputTokens: maxOutput,
          model: modelId,
          noImageSupport: !m.attachment,
        },
      }
    })
}

const buildZaiEntries = (): { compaction: number; entry: { id: string } & Record<string, unknown> }[] =>
  ZAI_MODELS.map((m, i) => {
    const slug = slugForId(m.model)
    return {
      compaction: computeCompactionLimit(m.context, ZAI_OVERRIDES.maxOutputTokens),
      entry: {
        ...ZAI_OVERRIDES,
        displayName: `${m.displayName} - Z.AI`,
        id: `custom:${slug}-zai`,
        index: i,
        model: m.model,
      },
    }
  })

const writeSettings = async (
  customModels: Record<string, unknown>[],
  compactionTokenLimitPerModel: Record<string, number>,
): Promise<void> => {
  try {
    await access(SETTINGS_PATH)
  } catch {
    throw new Error(`Settings file not found: ${SETTINGS_PATH}`)
  }
  const raw = await readFile(SETTINGS_PATH, 'utf-8')
  const settings = {
    // oxlint-disable-next-line rules/no-sync-decode
    ...Schema.decodeUnknownSync(Schema.Record(Schema.String, Schema.Unknown))(JSON.parse(raw)),
    compactionTokenLimitPerModel,
    customModels,
  }

  const trailingNewline = raw.endsWith('\n') ? '\n' : ''
  await writeFile(SETTINGS_PATH, JSON.stringify(settings, null, 2) + trailingNewline)
  console.error(`Updated ${SETTINGS_PATH}`)
  console.error(`  customModels: ${customModels.length} entries`)
  console.error(`  compactionTokenLimitPerModel: ${Object.keys(compactionTokenLimitPerModel).length} entries`)
}

// ── Main ─────────────────────────────────────────────────────────────────────

const main = async (): Promise<void> => {
  const args = new Set(process.argv.slice(2))
  const writeMode = args.has('--write') || args.has('-w')

  const resp = await fetch(MODELS_DEV_URL)
  // oxlint-disable-next-line rules/no-sync-decode
  const data = Schema.decodeUnknownSync(ProviderSchema)(await resp.json())

  const anthropic = buildAnthropicEntries(data)
  const opencodeGo = buildOpencodeGoEntries(data)
  const zai = buildZaiEntries()

  const all = [...anthropic, ...opencodeGo, ...zai]

  const customModels = all.map((e, i) => ({ ...e.entry, index: i }))
  const compactionTokenLimitPerModel: Record<string, number> = {}
  for (const { entry, compaction } of all) {
    compactionTokenLimitPerModel[entry.id] = compaction
  }

  if (writeMode) {
    await writeSettings(customModels, compactionTokenLimitPerModel)
  } else {
    const output = { compactionTokenLimitPerModel, customModels }
    console.log(JSON.stringify(output, null, 2))
  }
}

const run = async (): Promise<void> => {
  try {
    await main()
  } catch (error: unknown) {
    const err = error instanceof Error ? error : new Error(String(error))
    console.error(`Error: ${err.message}`)
    process.exit(1)
  }
}

void run()
