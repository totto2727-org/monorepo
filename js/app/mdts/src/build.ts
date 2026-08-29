import { markdown } from 'vite-plugin-mdts'
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

export const resolveMdtsViteConfig = (config: ResolvedMdtsConfig, commandConfig: InlineConfig): InlineConfig => {
  const baseConfig: InlineConfig = {
    configFile: false,
    plugins: [markdown({ directory: config.input })],
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

export const buildMarkdown = async (options: MdtsCommandOptions): Promise<void> => {
  const config = await loadMdtsConfig({ command: 'build', ...options })
  const userBuild = config.vite.build
  const userRolldownOptions = userBuild?.rolldownOptions

  await build(
    resolveMdtsViteConfig(config, {
      build: {
        ...userBuild,
        emptyOutDir: true,
        outDir: config.output,
        rolldownOptions: {
          ...userRolldownOptions,
          input: buildEntryId,
        },
        write: true,
      },
      plugins: [buildEntryPlugin()],
    }),
  )
}
