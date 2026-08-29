import { build } from 'vite'
import type { Plugin, Rolldown } from 'vite'
import { describe, expect, test } from 'vite-plus/test'

import { formatMarkdownLink, parseLinkRequest } from './compiler.ts'
import { markdown, md } from './index.ts'

const virtualEntry = '\0vite-plugin-markdown-test-entry'

const virtualEntryPlugin = (): Plugin => ({
  load(id) {
    return id === virtualEntry ? 'export {}' : undefined
  },
  name: 'vite-plugin-markdown-test-entry',
  resolveId(id) {
    return id === virtualEntry ? virtualEntry : undefined
  },
})

describe('md', () => {
  test('preserves Markdown syntax and interpolates TypeScript values', () => {
    // Given
    const title = 'Guide'
    const itemCount = 2

    // When
    const document = md`# ${title}

Items: ${itemCount}
`

    // Then
    expect(document).toBe('# Guide\n\nItems: 2\n')
  })

  test('emits escaped template delimiters as Markdown code delimiters', () => {
    // Given
    const command = 'vp build'

    // When
    const document = md`Run \`${command}\`.`

    // Then
    expect(document).toBe('Run `vp build`.')
  })
})

describe('markdown', () => {
  test('emits multiple Markdown documents and converts link imports', async () => {
    // Given
    const projectRoot = new URL('__fixtures__/', import.meta.url).pathname
    const generatedAssets: Rolldown.OutputAsset[] = []
    const collectAssets = (): Plugin => ({
      generateBundle(_options, bundle) {
        for (const output of Object.values(bundle)) {
          if (output.type === 'asset') {
            generatedAssets.push(output)
          }
        }
      },
      name: 'vite-plugin-markdown-test-collector',
    })

    // When
    await build({
      build: {
        rolldownOptions: { input: virtualEntry },
        write: false,
      },
      configFile: false,
      logLevel: 'silent',
      plugins: [
        markdown({
          documents: {
            'guide.md': './guide.md.ts',
            'reference.md': './reference.md.ts',
          },
        }),
        virtualEntryPlugin(),
        collectAssets(),
      ],
      root: projectRoot,
    })

    // Then
    const documents = Object.fromEntries(generatedAssets.map((asset) => [asset.fileName, asset.source]))

    expect(documents).toEqual({
      'guide.md': '# Guide\n\n[Reference](reference.md)\n',
      'reference.md': '# Reference\n',
    })
  })

  test('uses text and hash query parameters for a link import', () => {
    // Given
    const request = {
      hash: 'api',
      path: './reference.md.ts',
      query: 'link&text=Details&hash=api',
      text: 'Details',
    }

    // When
    const parsed = parseLinkRequest('./reference.md.ts?link&text=Details&hash=api')
    const link = formatMarkdownLink({ destination: 'reference.md', request, title: 'Reference' })

    // Then
    expect(parsed).toEqual(request)
    expect(link).toBe('[Details](reference.md#api)')
  })
})
