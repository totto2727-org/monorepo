import { Predicate } from 'effect'
import { normalizePath } from 'vite'
import type { Plugin } from 'vite'

import {
  compileMarkdownModule,
  formatMarkdownLink,
  MarkdownCompileError,
  parseLinkRequest,
  readMarkdownTitle,
} from './compiler.ts'
import type { LinkRequest } from './compiler.ts'

export type MarkdownTemplateValue = bigint | number | string

export interface MarkdownPluginOptions {
  readonly documents: Readonly<Record<string, string>>
}

interface RenderMarkdownLinkOptions {
  readonly fileNameBySource: ReadonlyMap<string, string>
  readonly request: LinkRequest
  readonly sourcePath: string
}

interface MarkdownPluginState {
  readonly fileNameBySource: Map<string, string>
  root: string
}

export const md = (strings: TemplateStringsArray, ...values: readonly MarkdownTemplateValue[]): string =>
  strings.map((segment, index) => `${segment}${values[index] ?? ''}`).join('')

const renderMarkdownLink = (options: RenderMarkdownLinkOptions): string => {
  const fileName = options.fileNameBySource.get(options.sourcePath)
  if (!Predicate.isString(fileName)) {
    throw new MarkdownCompileError(options.sourcePath, 'the linked document is not configured for output')
  }

  const title = options.request.text ?? readMarkdownTitle(options.sourcePath)
  return formatMarkdownLink({ destination: fileName, request: options.request, title })
}

export const markdown = (options: MarkdownPluginOptions): Plugin => {
  const state: MarkdownPluginState = { fileNameBySource: new Map(), root: '' }

  return {
    apply: 'build',
    async buildStart() {
      await Promise.all(
        Object.entries(options.documents).map(async ([fileName, input]) => {
          const sourceId = input.startsWith('/') ? input : `${state.root}/${input}`
          const resolved = await this.resolve(sourceId, undefined, { skipSelf: true })
          const resolvedId = resolved?.id
          if (!Predicate.isString(resolvedId)) {
            throw new MarkdownCompileError(sourceId, 'could not resolve the configured document')
          }

          const sourcePath = normalizePath(resolvedId)
          state.fileNameBySource.set(sourcePath, fileName)
          this.emitFile({ id: sourcePath, type: 'chunk' })
        }),
      )
    },
    configResolved(config) {
      state.root = normalizePath(config.root)
    },
    enforce: 'pre',
    generateBundle(_outputOptions, bundle) {
      for (const [fileName, output] of Object.entries(bundle)) {
        if (
          output.type === 'chunk' &&
          Predicate.isString(output.facadeModuleId) &&
          state.fileNameBySource.has(normalizePath(output.facadeModuleId))
        ) {
          Reflect.deleteProperty(bundle, fileName)
        }
      }
    },
    load(id) {
      const request = parseLinkRequest(id)
      if (Predicate.isNullish(request)) {
        return null
      }

      const sourcePath = normalizePath(request.path)
      const value = renderMarkdownLink({ fileNameBySource: state.fileNameBySource, request, sourcePath })

      return `import ${JSON.stringify(sourcePath)}\nexport default ${JSON.stringify(value)}\n`
    },
    name: 'vite-plugin-markdown',
    async resolveId(source, importer) {
      const request = parseLinkRequest(source)
      if (Predicate.isNullish(request)) {
        return null
      }

      const resolved = await this.resolve(request.path, importer, { skipSelf: true })
      const resolvedId = resolved?.id
      if (!Predicate.isString(resolvedId)) {
        throw new MarkdownCompileError(importer ?? source, `could not resolve ${request.path}`)
      }

      return `${normalizePath(resolvedId)}?${request.query}`
    },
    async transform(code, id) {
      const sourcePath = normalizePath(id)
      const fileName = state.fileNameBySource.get(sourcePath)
      if (!Predicate.isString(fileName)) {
        return null
      }

      const compiled = await compileMarkdownModule({
        code,
        id: sourcePath,
        resolveLink: async (specifier) => {
          const request = parseLinkRequest(specifier)
          if (Predicate.isNullish(request)) {
            throw new MarkdownCompileError(sourcePath, `invalid link import ${specifier}`)
          }

          const resolved = await this.resolve(request.path, sourcePath, { skipSelf: true })
          const resolvedId = resolved?.id
          if (!Predicate.isString(resolvedId)) {
            throw new MarkdownCompileError(sourcePath, `could not resolve ${request.path}`)
          }

          return renderMarkdownLink({
            fileNameBySource: state.fileNameBySource,
            request,
            sourcePath: normalizePath(resolvedId),
          })
        },
      })

      this.emitFile({ fileName, source: compiled.source, type: 'asset' })
      return { code: compiled.code, map: null }
    },
  }
}
