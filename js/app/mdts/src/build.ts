import { NodeServices } from '@effect/platform-node'
import { Effect, FileSystem } from 'effect'
import {
  compileMarkdownDocuments as compileLoadedMarkdownDocuments,
  markdown,
  markdownDocumentsId,
} from 'vite-plugin-mdts'
import type { CompiledMarkdownDocument } from 'vite-plugin-mdts'
import { createServer, mergeConfig, normalizePath } from 'vite-plus'
import type { InlineConfig, ViteDevServer } from 'vite-plus'

import { loadMdtsConfig } from './config.ts'
import type { ResolvedMdtsConfig } from './config.ts'

interface MdtsCommandOptions {
  readonly configFile?: string
  readonly root: string
}

export const resolveMdtsViteConfig = (config: ResolvedMdtsConfig, commandConfig: InlineConfig): InlineConfig => {
  const baseConfig: InlineConfig = {
    appType: 'custom',
    configFile: false,
    plugins: [markdown({ directory: config.input })],
    publicDir: false,
    root: config.root,
  }
  const merged = mergeConfig(mergeConfig(baseConfig, config.vite), commandConfig)

  return {
    ...merged,
    appType: 'custom',
    configFile: false,
    publicDir: false,
    root: config.root,
  }
}

const compileWithServer = async (
  config: ResolvedMdtsConfig,
  server: ViteDevServer,
): Promise<readonly CompiledMarkdownDocument[]> => {
  const loaded = await server.ssrLoadModule(markdownDocumentsId)
  return compileLoadedMarkdownDocuments({
    directory: config.input,
    modules: loaded.default,
    root: config.root,
  })
}

export const compileResolvedMarkdownDocuments = async (
  config: ResolvedMdtsConfig,
  server?: ViteDevServer,
): Promise<readonly CompiledMarkdownDocument[]> => {
  if (server) {
    return await compileWithServer(config, server)
  }

  const ownedServer = await createServer(resolveMdtsViteConfig(config, {}))
  try {
    return await compileWithServer(config, ownedServer)
  } finally {
    await ownedServer.close()
  }
}

export const compileMarkdownDocuments = async (
  options: MdtsCommandOptions,
): Promise<readonly CompiledMarkdownDocument[]> => {
  const config = await loadMdtsConfig({ command: 'build', ...options })
  return await compileResolvedMarkdownDocuments(config)
}

const outputDirectory = (config: ResolvedMdtsConfig): string => {
  const normalizedOutput = normalizePath(config.output).replace(/\/$/u, '')
  if (normalizedOutput.startsWith('/') || /^[A-Za-z]:\//u.test(normalizedOutput)) {
    return normalizedOutput
  }
  return `${normalizePath(config.root).replace(/\/$/u, '')}/${normalizedOutput}`
}

const parentDirectory = (filePath: string): string => filePath.slice(0, filePath.lastIndexOf('/'))

const writeMarkdownDocuments = (
  config: ResolvedMdtsConfig,
  documents: readonly CompiledMarkdownDocument[],
): Effect.Effect<void, unknown, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const output = outputDirectory(config)
    yield* fs.remove(output, { force: true, recursive: true })
    yield* fs.makeDirectory(output, { recursive: true })
    yield* Effect.forEach(
      documents,
      (document) => {
        const outputPath = `${output}/${document.fileName}`
        return Effect.gen(function* () {
          yield* fs.makeDirectory(parentDirectory(outputPath), { recursive: true })
          yield* fs.writeFileString(outputPath, document.source)
        })
      },
      { concurrency: 'unbounded', discard: true },
    )
  })

export const buildMarkdown = async (options: MdtsCommandOptions): Promise<void> => {
  const config = await loadMdtsConfig({ command: 'build', ...options })
  const documents = await compileResolvedMarkdownDocuments(config)
  // oxlint-disable-next-line rules/no-effect-runtime-run -- Public Promise API executes one filesystem workflow with the Node service layer.
  await Effect.runPromise(writeMarkdownDocuments(config, documents).pipe(Effect.provide(NodeServices.layer)))
}
