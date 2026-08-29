import { Predicate, String } from 'effect'
import { loadConfigFromFile, normalizePath } from 'vite-plus'
import type { ConfigEnv, UserConfig } from 'vite-plus'

const defaultConfigFile = 'mdts.config.ts'
const defaultInput = 'content'
const defaultOutput = 'dist'

export interface MdtsConfig {
  readonly input?: string
  readonly output?: string
  readonly vite?: UserConfig
}

export interface ResolvedMdtsConfig {
  readonly configFile: string
  readonly input: string
  readonly output: string
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

  return {
    configFile: loaded.path,
    input: resolveInput(config.input),
    output: resolveOutput(config.output),
    root: options.root,
    vite: config.vite ?? {},
  }
}
