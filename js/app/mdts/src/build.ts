import { markdown } from 'vite-plugin-mdts'
import type { CompiledMarkdownDocument } from 'vite-plugin-mdts'
import { build, mergeConfig } from 'vite-plus'
import type { InlineConfig, Plugin } from 'vite-plus'

import { loadMdtsConfig } from './config.ts'
import type { ResolvedMdtsConfig } from './config.ts'

const buildEntryId = 'virtual:mdts/build-entry'
const resolvedBuildEntryId = '\0mdts:build-entry'

interface MdtsCommandOptions {
  readonly configFile?: string
  readonly root: string
}

interface ExecuteMarkdownBuildOptions {
  readonly onCompiled?: (document: CompiledMarkdownDocument) => void
  readonly write: boolean
}

const buildEntryPlugin = (): Plugin => ({
  generateBundle(_options, bundle) {
    for (const [fileName, output] of Object.entries(bundle)) {
      if (output.type === 'chunk' && output.facadeModuleId === resolvedBuildEntryId) {
        Reflect.deleteProperty(bundle, fileName)
      }
    }
  },
  load(id) {
    return id === resolvedBuildEntryId ? 'export {}\n' : undefined
  },
  name: 'mdts-build-entry',
  resolveId(id) {
    return id === buildEntryId ? resolvedBuildEntryId : undefined
  },
})

export const resolveMdtsViteConfig = (
  config: ResolvedMdtsConfig,
  commandConfig: InlineConfig,
  onCompiled?: (document: CompiledMarkdownDocument) => void,
): InlineConfig => {
  const baseConfig: InlineConfig = {
    configFile: false,
    plugins: [markdown({ directory: config.input, onCompiled })],
    publicDir: false,
    root: config.root,
  }
  const merged = mergeConfig(mergeConfig(baseConfig, config.vite), commandConfig)

  return {
    ...merged,
    configFile: false,
    publicDir: false,
    root: config.root,
  }
}

const executeMarkdownBuild = async (
  config: ResolvedMdtsConfig,
  options: ExecuteMarkdownBuildOptions,
): Promise<void> => {
  const userBuild = config.vite.build
  const userRolldownOptions = userBuild?.rolldownOptions

  await build(
    resolveMdtsViteConfig(
      config,
      {
        build: {
          ...userBuild,
          emptyOutDir: options.write,
          outDir: config.output,
          rolldownOptions: {
            ...userRolldownOptions,
            input: buildEntryId,
          },
          write: options.write,
        },
        plugins: [buildEntryPlugin()],
      },
      options.onCompiled,
    ),
  )
}

export const compileResolvedMarkdownDocuments = async (
  config: ResolvedMdtsConfig,
): Promise<readonly CompiledMarkdownDocument[]> => {
  const documents = new Map<string, CompiledMarkdownDocument>()
  await executeMarkdownBuild(config, {
    onCompiled: (document) => {
      documents.set(document.sourcePath, document)
    },
    write: false,
  })
  return [...documents.values()]
}

export const compileMarkdownDocuments = async (
  options: MdtsCommandOptions,
): Promise<readonly CompiledMarkdownDocument[]> => {
  const config = await loadMdtsConfig({ command: 'build', ...options })
  return await compileResolvedMarkdownDocuments(config)
}

export const buildMarkdown = async (options: MdtsCommandOptions): Promise<void> => {
  const config = await loadMdtsConfig({ command: 'build', ...options })
  await executeMarkdownBuild(config, { write: true })
}
