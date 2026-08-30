import type { createHtmlRenderer } from '@comark/html'
import type {
  TextlintKernelFilterRule,
  TextlintKernelPlugin,
  TextlintKernelRule,
  TextlintRuleModule,
  TextlintRuleOptions,
} from '@textlint/kernel'
import { Predicate, String } from 'effect'
import type {
  Configuration as MarkdownlintConfiguration,
  MarkdownItFactory,
  Rule as MarkdownlintRule,
} from 'markdownlint'
import { loadConfigFromFile, normalizePath } from 'vite-plus'
import type { ConfigEnv, UserConfig } from 'vite-plus'

export { defineMeta, defineNote, markdown, markdownDocumentsId, md, noteBody, noteRef } from 'vite-plugin-mdts'
export type {
  TextlintFilterRuleReporter,
  TextlintKernelFilterRule,
  TextlintKernelPlugin,
  TextlintKernelRule,
  TextlintPluginCreator,
  TextlintRuleModule,
  TextlintRuleOptions,
} from '@textlint/kernel'
export type {
  Configuration as MarkdownlintConfiguration,
  MarkdownItFactory,
  Rule as MarkdownlintRule,
} from 'markdownlint'
export type {
  DefinedMarkdownNotes,
  MarkdownContent,
  MarkdownFrontmatterValue,
  MarkdownLinkReference,
  MarkdownMetadata,
  MarkdownNote,
  MarkdownNoteInput,
  MarkdownPluginOptions,
  MarkdownTemplate,
  MarkdownTemplateValue,
} from 'vite-plugin-mdts'

const defaultConfigFile = 'mdts.config.ts'
const defaultInput = 'content'
const defaultOutput = 'dist'

export type MdtsComarkOptions = NonNullable<Parameters<typeof createHtmlRenderer>[0]>

export interface MdtsPreviewConfig {
  readonly comark?: MdtsComarkOptions
}

export type MdtsLintScope = 'file' | 'project'
export type MdtsLintTarget = 'dist' | 'source'

export interface MdtsLinterExecutionConfig<
  Target extends MdtsLintTarget = MdtsLintTarget,
  Scope extends MdtsLintScope = MdtsLintScope,
> {
  readonly scope?: Scope
  readonly target?: Target
}

export interface MdtsMarkdownlintConfig extends MdtsLinterExecutionConfig<'source', 'file'> {
  readonly config?: MarkdownlintConfiguration
  readonly customRules?: MarkdownlintRule | MarkdownlintRule[]
  readonly frontMatter?: RegExp | null
  readonly markdownItFactory?: MarkdownItFactory
  readonly noInlineConfig?: boolean
}

export interface MdtsTextlintRulePreset {
  readonly options?: Readonly<Record<string, TextlintRuleOptions | boolean>>
  readonly preset: {
    readonly rules: Readonly<Record<string, TextlintRuleModule>>
    readonly rulesConfig: Readonly<Record<string, TextlintRuleOptions | boolean>>
  }
  readonly presetId: string
}

export type MdtsTextlintPreset = 'en' | 'ja'

export interface MdtsTextlintConfig extends MdtsLinterExecutionConfig<'source', 'file'> {
  readonly filterRules?: readonly TextlintKernelFilterRule[]
  readonly plugins?: readonly TextlintKernelPlugin[]
  readonly preset?: false | MdtsTextlintPreset
  readonly presetOptions?: Readonly<Record<string, TextlintRuleOptions | boolean>>
  readonly presets?: readonly MdtsTextlintRulePreset[]
  readonly rules?: readonly TextlintKernelRule[]
}

export type MdtsKnipRule = 'error' | 'off' | 'warn'

export interface MdtsKnipConfig extends MdtsLinterExecutionConfig<'source', 'project'> {
  readonly entry?: readonly string[]
  readonly ignoreFiles?: readonly string[]
  readonly project?: readonly string[]
  readonly rule?: MdtsKnipRule
}

export interface MdtsLintConfig {
  readonly knip?: false | MdtsKnipConfig
  readonly markdownlint?: false | MdtsMarkdownlintConfig
  readonly textlint?: false | MdtsTextlintConfig
}

export interface MdtsConfig {
  readonly input?: string
  readonly lint?: MdtsLintConfig
  readonly output?: string
  readonly preview?: MdtsPreviewConfig
  readonly vite?: UserConfig
}

export interface ResolvedMdtsConfig {
  readonly configFile: string
  readonly input: string
  readonly lint: {
    readonly knip:
      | false
      | (MdtsKnipConfig & {
          readonly entry: readonly string[]
          readonly project: readonly string[]
          readonly rule: MdtsKnipRule
          readonly scope: 'project'
          readonly target: 'source'
        })
    readonly markdownlint: false | (MdtsMarkdownlintConfig & { readonly scope: 'file'; readonly target: 'source' })
    readonly textlint: false | (MdtsTextlintConfig & { readonly scope: 'file'; readonly target: 'source' })
  }
  readonly output: string
  readonly preview: {
    readonly comark: MdtsComarkOptions
  }
  readonly root: string
  readonly vite: UserConfig
}

interface LoadMdtsConfigOptions {
  readonly command: ConfigEnv['command']
  readonly configFile?: string
  readonly root: string
}

export const defineConfig = (config: MdtsConfig): MdtsConfig => config

const resolveInput = (input: string | undefined): string => {
  const rawInput = input ?? defaultInput
  const normalized = normalizePath(rawInput).replace(/^\.\//u, '').replace(/\/$/u, '')
  if (normalized.startsWith('/') || /^[A-Za-z]:\//u.test(normalized)) {
    throw new TypeError('mdts input must be relative to the project root')
  }
  if (normalized.split('/').includes('..')) {
    throw new TypeError('mdts input must stay within the project root')
  }

  return normalized
}

const resolveOutput = (output: string | undefined): string => {
  const resolved = output ?? defaultOutput
  if (String.isEmpty(resolved)) {
    throw new TypeError('mdts output must not be empty')
  }
  return resolved
}

const resolveUserConfig = (value: unknown): MdtsConfig => {
  if (!Predicate.isObject(value) || Array.isArray(value)) {
    throw new TypeError('mdts.config.ts must export a configuration object')
  }
  return value
}

const resolveKnipConfig = (knip: MdtsLintConfig['knip'], input: string): ResolvedMdtsConfig['lint']['knip'] => {
  if (knip === false) {
    return false
  }
  const defaultKnipEntry = String.isEmpty(input) ? '*.md.ts' : `${input}/*.md.ts`
  const defaultKnipProject = String.isEmpty(input) ? '**/*.md.ts' : `${input}/**/*.md.ts`
  return {
    entry: knip?.entry ?? [defaultKnipEntry],
    ...knip,
    project: knip?.project ?? [defaultKnipProject],
    rule: knip?.rule ?? 'error',
    scope: 'project',
    target: 'source',
  }
}

const resolveMarkdownlintConfig = (
  markdownlint: MdtsLintConfig['markdownlint'],
): ResolvedMdtsConfig['lint']['markdownlint'] => {
  if (markdownlint === false) {
    return false
  }
  return {
    ...markdownlint,
    config: {
      default: true,
      ...markdownlint?.config,
    },
    scope: 'file',
    target: 'source',
  }
}

const resolveTextlintConfig = (textlint: MdtsLintConfig['textlint']): ResolvedMdtsConfig['lint']['textlint'] => {
  if (textlint === false) {
    return false
  }
  return {
    preset: 'en',
    ...textlint,
    scope: 'file',
    target: 'source',
  }
}

const resolveLintConfig = (lint: MdtsLintConfig | undefined, input: string): ResolvedMdtsConfig['lint'] => ({
  knip: resolveKnipConfig(lint?.knip, input),
  markdownlint: resolveMarkdownlintConfig(lint?.markdownlint),
  textlint: resolveTextlintConfig(lint?.textlint),
})

export const loadMdtsConfig = async (options: LoadMdtsConfigOptions): Promise<ResolvedMdtsConfig> => {
  const requestedConfigFile = normalizePath(options.configFile ?? defaultConfigFile)
  const normalizedRoot = normalizePath(options.root).replace(/\/$/u, '')
  const configFile =
    requestedConfigFile.startsWith('/') || /^[A-Za-z]:\//u.test(requestedConfigFile)
      ? requestedConfigFile
      : `${normalizedRoot}/${requestedConfigFile}`
  const loaded = await loadConfigFromFile(
    {
      command: options.command,
      isPreview: options.command === 'serve',
      isSsrBuild: false,
      mode: options.command === 'build' ? 'production' : 'development',
    },
    configFile,
    options.root,
  )
  if (Predicate.isNullish(loaded)) {
    throw new TypeError(`could not load mdts config: ${configFile}`)
  }
  const config = resolveUserConfig(loaded.config)
  const input = resolveInput(config.input)

  return {
    configFile: loaded.path,
    input,
    lint: resolveLintConfig(config.lint, input),
    output: resolveOutput(config.output),
    preview: {
      comark: config.preview?.comark ?? {},
    },
    root: options.root,
    vite: config.vite ?? {},
  }
}
