import { build } from 'vite'
import type { Plugin, Rolldown } from 'vite'
import { describe, expect, test } from 'vite-plus/test'

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
  test('emits configured Markdown documents during a Vite build', async () => {
    // Given
    const source = '# Generated\n'
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
      plugins: [markdown({ documents: { 'guide.md': source } }), virtualEntryPlugin(), collectAssets()],
    })

    // Then
    const generatedAsset = generatedAssets.find((output) => output.fileName === 'guide.md')

    expect(generatedAsset).toMatchObject({ source, type: 'asset' })
  })
})
