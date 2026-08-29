import { Predicate, String } from 'effect'
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

export type MarkdownFrontmatterValue =
  | boolean
  | null
  | number
  | string
  | readonly MarkdownFrontmatterValue[]
  | { readonly [key: string]: MarkdownFrontmatterValue }

export interface MarkdownMetadata {
  readonly frontmatter?: Readonly<Record<string, MarkdownFrontmatterValue>>
  readonly title: string
}

export interface MarkdownPluginOptions {
  readonly directory: string
}

interface MarkdownPluginState {
  command: 'build' | 'serve'
  directory: string
  root: string
  sourceDirectory: string
}

interface RenderMarkdownLinkOptions {
  readonly currentFileName?: string
  readonly request: LinkRequest
  readonly sourcePath: string
  readonly state: MarkdownPluginState
}

export const markdownDocumentsId = 'virtual:vite-plugin-mdts/documents'
const resolvedVirtualDocumentsId = '\0vite-plugin-mdts:documents'

export const md = (strings: TemplateStringsArray, ...values: readonly MarkdownTemplateValue[]): string =>
  strings.map((segment, index) => `${segment}${values[index] ?? ''}`).join('')

const normalizeDirectory = (directory: string): string => {
  const segments = normalizePath(directory)
    .split('/')
    .filter((segment) => String.isNonEmpty(segment) && segment !== '.')

  if (segments.includes('..')) {
    throw new MarkdownCompileError(directory, 'the document directory must stay within the Vite root')
  }

  return segments.join('/')
}

const outputFileName = (state: MarkdownPluginState, sourcePath: string): string | undefined => {
  const prefix = `${state.sourceDirectory}/`
  if (!sourcePath.startsWith(prefix) || !sourcePath.endsWith('.md.ts')) {
    return undefined
  }

  return `${sourcePath.slice(prefix.length, -'.md.ts'.length)}.md`
}

const relativeDestination = (currentFileName: string, targetFileName: string): string => {
  const currentDirectory = currentFileName.split('/').slice(0, -1)
  const target = targetFileName.split('/')
  const firstDifferentSegment = currentDirectory.findIndex((segment, index) => segment !== target[index])
  const sharedSegments = firstDifferentSegment === -1 ? currentDirectory.length : firstDifferentSegment

  return [...currentDirectory.slice(sharedSegments).map(() => '..'), ...target.slice(sharedSegments)].join('/')
}

const renderMarkdownLink = (options: RenderMarkdownLinkOptions): string => {
  const targetFileName = outputFileName(options.state, options.sourcePath)
  if (!Predicate.isString(targetFileName)) {
    throw new MarkdownCompileError(options.sourcePath, 'the linked document is outside the configured directory')
  }

  const destination = Predicate.isString(options.currentFileName)
    ? relativeDestination(options.currentFileName, targetFileName)
    : targetFileName
  const title = options.request.text ?? readMarkdownTitle(options.sourcePath)
  return formatMarkdownLink({ destination, request: options.request, title })
}

export const markdown = (options: MarkdownPluginOptions): Plugin => {
  const state: MarkdownPluginState = { command: 'build', directory: '', root: '', sourceDirectory: '' }

  return {
    buildStart() {
      if (state.command === 'build') {
        this.emitFile({ id: markdownDocumentsId, type: 'chunk' })
      }
    },
    configResolved(config) {
      state.command = config.command
      state.root = normalizePath(config.root).replace(/\/$/u, '')
      state.directory = normalizeDirectory(options.directory)
      state.sourceDirectory = String.isEmpty(state.directory) ? state.root : `${state.root}/${state.directory}`
    },
    enforce: 'pre',
    generateBundle(_outputOptions, bundle) {
      for (const [fileName, output] of Object.entries(bundle)) {
        if (output.type === 'chunk' && output.facadeModuleId === resolvedVirtualDocumentsId) {
          Reflect.deleteProperty(bundle, fileName)
        }
      }
    },
    load(id) {
      if (id === resolvedVirtualDocumentsId) {
        const glob = String.isEmpty(state.directory) ? '/**/*.md.ts' : `/${state.directory}/**/*.md.ts`
        return `export default import.meta.glob(${JSON.stringify(glob)}, { eager: true })\n`
      }

      const request = parseLinkRequest(id)
      if (Predicate.isNullish(request)) {
        return null
      }

      const sourcePath = normalizePath(request.path)
      const value = renderMarkdownLink({ request, sourcePath, state })
      return `import ${JSON.stringify(sourcePath)}\nexport default ${JSON.stringify(value)}\n`
    },
    name: 'vite-plugin-mdts',
    async resolveId(source, importer) {
      if (source === markdownDocumentsId) {
        return resolvedVirtualDocumentsId
      }

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
      const fileName = outputFileName(state, sourcePath)
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
            currentFileName: fileName,
            request,
            sourcePath: normalizePath(resolvedId),
            state,
          })
        },
      })

      if (state.command === 'build') {
        this.emitFile({ fileName, source: compiled.source, type: 'asset' })
      }
      return { code: compiled.code, map: null }
    },
  }
}
