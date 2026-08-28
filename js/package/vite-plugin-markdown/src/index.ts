import type { Plugin } from 'vite'

export type MarkdownTemplateValue = bigint | number | string

export interface MarkdownPluginOptions {
  readonly documents: Readonly<Record<string, string>>
}

export const md = (strings: TemplateStringsArray, ...values: readonly MarkdownTemplateValue[]): string =>
  strings.map((segment, index) => `${segment}${values[index] ?? ''}`).join('')

export const markdown = (options: MarkdownPluginOptions): Plugin => ({
  apply: 'build',
  buildStart() {
    for (const [fileName, source] of Object.entries(options.documents)) {
      this.emitFile({ fileName, source, type: 'asset' })
    }
  },
  name: 'vite-plugin-markdown',
})
