import { Predicate, String } from 'effect'
import { normalizePath } from 'vite'
import type { Plugin } from 'vite'

import { MarkdownCompileError, normalizeMarkdownDirectory, parseLinkRequest } from './compiler.ts'

export { compileMarkdownDocuments, generatedFileNotice, MarkdownCompileError } from './compiler.ts'
export type { CompiledMarkdownDocument, MarkdownSourcePosition } from './compiler.ts'
export { defineMeta, defineNote, md, noteBody, noteRef } from './runtime.ts'
export type {
  DefinedMarkdownNotes,
  MarkdownContent,
  MarkdownFrontmatterValue,
  MarkdownLinkReference,
  MarkdownMetadata,
  MarkdownNote,
  MarkdownNoteInput,
  MarkdownTemplate,
  MarkdownTemplateValue,
} from './runtime.ts'

export interface MarkdownPluginOptions {
  readonly directory: string
}

interface MarkdownPluginState {
  directory: string
}

export const markdownDocumentsId = 'virtual:vite-plugin-mdts/documents'
const resolvedVirtualDocumentsId = '\0vite-plugin-mdts:documents'

export const markdown = (options: MarkdownPluginOptions): Plugin => {
  const state: MarkdownPluginState = { directory: '' }

  return {
    configResolved() {
      state.directory = normalizeMarkdownDirectory(options.directory)
    },
    enforce: 'pre',
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
      this.addWatchFile(sourcePath)
      return `export default Object.freeze(${JSON.stringify({
        hash: request.hash,
        kind: 'vite-plugin-mdts/link',
        targetPath: sourcePath,
        text: request.text,
      })})\n`
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
  }
}
