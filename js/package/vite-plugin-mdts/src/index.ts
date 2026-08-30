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
import type { LinkRequest, MarkdownSourcePosition } from './compiler.ts'

export { generatedFileNotice } from './compiler.ts'
export type { MarkdownSourcePosition } from './compiler.ts'

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

export interface MarkdownNoteInput {
  readonly body: string
  readonly slug: string
}

export interface MarkdownNote extends MarkdownNoteInput {
  readonly index: string
}

export type DefinedMarkdownNotes<
  Notes extends readonly MarkdownNoteInput[],
  Position extends readonly unknown[] = readonly [],
> = Notes extends readonly []
  ? readonly []
  : Notes extends readonly [infer Note extends MarkdownNoteInput, ...infer Rest extends readonly MarkdownNoteInput[]]
    ? readonly [
        Readonly<Note & { readonly index: `${[...Position, unknown]['length']}` }>,
        ...DefinedMarkdownNotes<Rest, readonly [...Position, unknown]>,
      ]
    : readonly MarkdownNote[]

export interface MarkdownPluginOptions {
  readonly directory: string
  readonly onCompiled?: (document: CompiledMarkdownDocument) => void
}

export interface CompiledMarkdownDocument {
  readonly fileName: string
  readonly source: string
  readonly sourceMap: readonly MarkdownSourcePosition[]
  readonly sourcePath: string
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
  strings
    .map((segment, index) => `${segment}${values[index] ?? ''}`)
    .join('')
    .trim()

export const defineNote = <const Notes extends readonly MarkdownNoteInput[]>(
  notes: Notes,
): DefinedMarkdownNotes<Notes> => {
  const slugs = new Set<string>()
  const definitions = notes.map((note, index) => {
    if (slugs.has(note.slug)) {
      throw new TypeError(`Duplicate Markdown note slug: ${note.slug}`)
    }
    slugs.add(note.slug)
    return Object.freeze({ ...note, body: note.body.trim(), index: `${index + 1}` })
  })
  // oxlint-disable-next-line typescript/no-unsafe-type-assertion -- Runtime mapping preserves tuple length, order, and the sequential indexes represented by DefinedMarkdownNotes.
  return Object.freeze(definitions) as DefinedMarkdownNotes<Notes>
}

const findNote = <Notes extends readonly MarkdownNote[]>(notes: Notes, slug: Notes[number]['slug']): MarkdownNote => {
  const note = notes.find((candidate) => candidate.slug === slug)
  if (Predicate.isNullish(note)) {
    throw new TypeError(`Unknown Markdown note slug: ${slug}`)
  }
  return note
}

export const noteRef = <Notes extends readonly MarkdownNote[]>(notes: Notes, slug: Notes[number]['slug']): string =>
  `[^${findNote(notes, slug).index}]`

export const noteBody = <Notes extends readonly MarkdownNote[]>(notes: Notes, slug: Notes[number]['slug']): string => {
  const note = findNote(notes, slug)
  return `[^${note.index}]: ${note.body}`
}

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

      options.onCompiled?.({
        fileName,
        source: compiled.source,
        sourceMap: compiled.sourceMap,
        sourcePath,
      })

      if (state.command === 'build') {
        this.emitFile({ fileName, source: compiled.source, type: 'asset' })
      }
      return { code: compiled.code, map: null }
    },
  }
}
