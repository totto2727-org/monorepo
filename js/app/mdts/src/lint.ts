import { TextlintKernelDescriptor } from '@textlint/kernel'
import type { TextlintKernelRule } from '@textlint/kernel'
import { moduleInterop } from '@textlint/module-interop'
import markdownPluginModule from '@textlint/textlint-plugin-markdown'
import { Array, Predicate } from 'effect'
import { createOptions, createSession } from 'knip/session'
import { lint as lintWithMarkdownlint } from 'markdownlint/promise'
import { createLinter } from 'textlint'
import { generatedFileNotice } from 'vite-plugin-mdts'
import type { CompiledMarkdownDocument } from 'vite-plugin-mdts'
import { normalizePath } from 'vite-plus'

import { compileResolvedMarkdownDocuments } from './build.ts'
import { loadMdtsConfig } from './config.ts'
import type {
  MdtsLintScope,
  MdtsLintTarget,
  MdtsTextlintPreset,
  MdtsTextlintRulePreset,
  ResolvedMdtsConfig,
} from './config.ts'

interface MdtsLintOptions {
  readonly configFile?: string
  readonly root: string
}

export type MdtsLintEngine = 'knip' | 'markdownlint' | 'textlint'
export type MdtsLintSeverity = 'error' | 'info' | 'warning'

export interface MdtsLintDiagnostic {
  readonly column: number
  readonly engine: MdtsLintEngine
  readonly filePath: string
  readonly line: number
  readonly message: string
  readonly ruleId: string
  readonly scope: MdtsLintScope
  readonly severity: MdtsLintSeverity
  readonly target: MdtsLintTarget
}

export interface MdtsLintResult {
  readonly diagnostics: readonly MdtsLintDiagnostic[]
  readonly errorCount: number
}

const escapedGeneratedFileNotice = generatedFileNotice.replaceAll(/[.*+?^${}()|[\]\\]/gu, '\\$&')
const generatedFrontMatter = new RegExp(
  `^(?:---\\r?\\n[\\s\\S]*?\\r?\\n---\\r?\\n\\r?\\n)?${escapedGeneratedFileNotice}\\r?\\n\\r?\\n`,
  'u',
)

const relativeSourcePath = (config: ResolvedMdtsConfig, sourcePath: string): string => {
  const normalizedRoot = normalizePath(config.root).replace(/\/$/u, '')
  const normalizedSourcePath = normalizePath(sourcePath)
  const rootPrefix = `${normalizedRoot}/`
  return normalizedSourcePath.startsWith(rootPrefix)
    ? normalizedSourcePath.slice(rootPrefix.length)
    : normalizedSourcePath
}

const mappedDiagnostic = (
  config: ResolvedMdtsConfig,
  document: CompiledMarkdownDocument,
  diagnostic: Omit<MdtsLintDiagnostic, 'column' | 'filePath' | 'line'> & {
    readonly generatedColumn: number
    readonly generatedLine: number
  },
): MdtsLintDiagnostic => {
  const position = document.sourceMap[diagnostic.generatedLine - 1]
  return {
    column: position ? position.column + diagnostic.generatedColumn - 1 : diagnostic.generatedColumn,
    engine: diagnostic.engine,
    filePath: relativeSourcePath(config, document.sourcePath),
    line: position?.line ?? diagnostic.generatedLine,
    message: diagnostic.message,
    ruleId: diagnostic.ruleId,
    scope: diagnostic.scope,
    severity: diagnostic.severity,
    target: diagnostic.target,
  }
}

const lintMarkdownlint = async (
  config: ResolvedMdtsConfig,
  documents: readonly CompiledMarkdownDocument[],
): Promise<readonly MdtsLintDiagnostic[]> => {
  const { markdownlint } = config.lint
  if (markdownlint === false) {
    return []
  }

  const results = await lintWithMarkdownlint({
    config: markdownlint.config,
    customRules: markdownlint.customRules,
    // oxlint-disable-next-line rules/prefer-is-nullish -- markdownlint uses null to disable front matter while undefined selects mdts defaults.
    frontMatter: Predicate.isUndefined(markdownlint.frontMatter) ? generatedFrontMatter : markdownlint.frontMatter,
    markdownItFactory: markdownlint.markdownItFactory,
    noInlineConfig: markdownlint.noInlineConfig,
    strings: Object.fromEntries(documents.map((document) => [document.fileName, document.source])),
  })
  const documentsByFileName = new Map(documents.map((document) => [document.fileName, document]))

  return Object.entries(results).flatMap(([fileName, lintErrors]) => {
    const document = documentsByFileName.get(fileName)
    if (!document) {
      return []
    }
    return lintErrors.map((lintError) =>
      mappedDiagnostic(config, document, {
        engine: 'markdownlint',
        generatedColumn: lintError.errorRange?.[0] ?? 1,
        generatedLine: lintError.lineNumber,
        message: Predicate.isString(lintError.errorDetail)
          ? `${lintError.ruleDescription}: ${lintError.errorDetail}`
          : lintError.ruleDescription,
        ruleId: lintError.ruleNames[0] ?? 'unknown',
        scope: markdownlint.scope,
        severity: lintError.severity,
        target: markdownlint.target,
      }),
    )
  })
}

const presetRules = (preset: MdtsTextlintRulePreset): readonly TextlintKernelRule[] => {
  const normalizedPreset = moduleInterop(preset.preset)
  return Object.entries(normalizedPreset.rules).map(([ruleKey, rule]) => {
    const configured = preset.options?.[ruleKey]
    const options =
      Predicate.isNullish(configured) || configured === true
        ? (normalizedPreset.rulesConfig[ruleKey] ?? true)
        : configured
    return {
      options,
      rule: moduleInterop(rule),
      ruleId: `${preset.presetId}/${ruleKey}`,
    }
  })
}

const builtInPreset = async (
  preset: MdtsTextlintPreset,
  options: MdtsTextlintRulePreset['options'],
): Promise<MdtsTextlintRulePreset> => {
  const presetModule =
    preset === 'en' ? await import('slopless') : await import('textlint-rule-preset-ja-technical-writing')
  return {
    options,
    preset: presetModule.default,
    presetId: preset === 'en' ? 'slopless' : 'preset-ja-technical-writing',
  }
}

const textlintSeverity = (severity: number): MdtsLintSeverity => {
  if (severity === 2) {
    return 'error'
  }
  if (severity === 1) {
    return 'warning'
  }
  return 'info'
}

const lintTextlint = async (
  config: ResolvedMdtsConfig,
  documents: readonly CompiledMarkdownDocument[],
  builtInTextlintPreset: MdtsTextlintRulePreset | null,
): Promise<readonly MdtsLintDiagnostic[]> => {
  const { textlint } = config.lint
  if (textlint === false) {
    return []
  }

  const builtInRules = builtInTextlintPreset ? presetRules(builtInTextlintPreset) : []
  const rules = [
    ...(textlint.rules ?? []).map((rule) => ({ ...rule, rule: moduleInterop(rule.rule) })),
    ...builtInRules,
    ...(textlint.presets ?? []).flatMap(presetRules),
  ]
  if (Array.isReadonlyArrayEmpty(rules)) {
    return []
  }

  const customPlugins = (textlint.plugins ?? []).map((plugin) => ({
    ...plugin,
    plugin: moduleInterop(plugin.plugin),
  }))
  const hasMarkdownPlugin = customPlugins.some((plugin) => plugin.pluginId === 'markdown')
  const descriptor = new TextlintKernelDescriptor({
    configBaseDir: config.root,
    filterRules: (textlint.filterRules ?? []).map((filterRule) => ({
      ...filterRule,
      rule: moduleInterop(filterRule.rule),
    })),
    plugins: hasMarkdownPlugin
      ? customPlugins
      : [...customPlugins, { plugin: moduleInterop(markdownPluginModule), pluginId: 'markdown' }],
    rules,
  })
  const linter = createLinter({ cwd: config.root, descriptor })
  const results = await Promise.all(
    documents.map(async (document) => ({
      document,
      result: await linter.lintText(document.source, document.fileName),
    })),
  )

  return results.flatMap(({ document, result }) =>
    result.messages.map((message) =>
      mappedDiagnostic(config, document, {
        engine: 'textlint',
        generatedColumn: message.loc.start.column,
        generatedLine: message.loc.start.line,
        message: message.message,
        ruleId: message.ruleId,
        scope: textlint.scope,
        severity: textlintSeverity(message.severity),
        target: textlint.target,
      }),
    ),
  )
}

const lintKnip = async (config: ResolvedMdtsConfig): Promise<readonly MdtsLintDiagnostic[]> => {
  const { knip } = config.lint
  if (knip === false || knip.rule === 'off') {
    return []
  }

  const options = await createOptions({
    cwd: config.root,
    includedIssueTypes: ['files'],
    isSession: true,
    isShowProgress: false,
    isUseTscFiles: false,
  })
  const configuredIgnoreFiles = options.parsedConfig.ignoreFiles
  options.parsedConfig = {
    ...options.parsedConfig,
    entry: [...knip.entry],
    ignoreFiles: [
      ...(Predicate.isString(configuredIgnoreFiles) ? [configuredIgnoreFiles] : (configuredIgnoreFiles ?? [])),
      ...(knip.ignoreFiles ?? []),
    ],
    project: [...knip.project],
  }
  options.rules = { ...options.rules, files: knip.rule }
  const session = await createSession(options)
  const issues = Object.values(session.getResults().issues.files).flatMap((records) => Object.values(records))

  return issues.flatMap((issue): readonly MdtsLintDiagnostic[] => {
    if (!issue.filePath.endsWith('.md.ts') || issue.severity === 'off') {
      return []
    }
    return [
      {
        column: issue.col ?? 1,
        engine: 'knip',
        filePath: relativeSourcePath(config, issue.filePath),
        line: issue.line ?? 1,
        message: 'Markdown source file is not reachable from an entry document',
        ruleId: issue.type,
        scope: knip.scope,
        severity: issue.severity === 'warn' ? 'warning' : 'error',
        target: knip.target,
      },
    ]
  })
}

const compareDiagnostics = (left: MdtsLintDiagnostic, right: MdtsLintDiagnostic): number =>
  left.filePath.localeCompare(right.filePath) ||
  left.line - right.line ||
  left.column - right.column ||
  left.engine.localeCompare(right.engine) ||
  left.ruleId.localeCompare(right.ruleId)

export const lintMarkdown = async (options: MdtsLintOptions): Promise<MdtsLintResult> => {
  const config = await loadMdtsConfig({ command: 'build', ...options })
  const { textlint } = config.lint
  const builtInTextlintPresetPromise: Promise<MdtsTextlintRulePreset | null> =
    textlint === false || textlint.preset === false
      ? Promise.resolve(null)
      : builtInPreset(textlint.preset ?? 'en', textlint.presetOptions)
  const [documents, builtInTextlintPreset, knipDiagnostics] = await Promise.all([
    compileResolvedMarkdownDocuments(config),
    builtInTextlintPresetPromise,
    lintKnip(config),
  ])
  const fileDiagnostics = await Promise.all([
    lintMarkdownlint(config, documents),
    lintTextlint(config, documents, builtInTextlintPreset),
  ])
  const diagnostics = [knipDiagnostics, ...fileDiagnostics].flat().toSorted(compareDiagnostics)

  return {
    diagnostics,
    errorCount: diagnostics.filter((diagnostic) => diagnostic.severity === 'error').length,
  }
}

export const formatLintResult = (result: MdtsLintResult): string =>
  result.diagnostics
    .map(
      (diagnostic) =>
        `${diagnostic.filePath}:${diagnostic.line}:${diagnostic.column} ${diagnostic.severity} ${diagnostic.message} (${diagnostic.engine}/${diagnostic.ruleId})`,
    )
    .join('\n')
