import { build } from 'vite'
import type { Plugin, Rolldown } from 'vite'
import { describe, expect, test } from 'vite-plus/test'

import { compileMarkdownModule, formatMarkdownLink, parseLinkRequest } from './compiler.ts'
import { markdown, md } from './index.ts'

const virtualEntry = '\0vite-plugin-mdts-test-entry'

const virtualEntryPlugin = (): Plugin => ({
  load(id) {
    return id === virtualEntry ? 'export {}' : undefined
  },
  name: 'vite-plugin-mdts-test-entry',
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
  test('prepends metadata titles and frontmatter, emits documents, and converts link imports', async () => {
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
      name: 'vite-plugin-mdts-test-collector',
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
          directory: '.',
        }),
        virtualEntryPlugin(),
        collectAssets(),
      ],
      root: projectRoot,
    })

    // Then
    const documents = Object.fromEntries(generatedAssets.map((asset) => [asset.fileName, asset.source]))

    expect(documents).toEqual({
      'guide.md':
        "---\ndescription: Generated from TypeScript metadata.\ntags:\n  - markdown\n  - typescript\ndraft: false\nmetadata:\n  version: '1.0'\n---\n\n# Guide\n\n[Details](reference/api.md#api)\n",
      'reference/api.md': '# Reference\n\n',
    })
  })

  test('requires frontmatter values to be statically declared', async () => {
    // Given
    const code = `import { md } from 'vite-plugin-mdts'
const description = 'dynamic'
export const meta = { frontmatter: { description }, title: 'Guide' }
export default md\`Body.
\`
`

    // When
    const compile = compileMarkdownModule({
      code,
      id: '/content/dynamic-frontmatter.md.ts',
      resolveLink: () => Promise.resolve(''),
    })

    // Then
    await expect(compile).rejects.toThrow('meta.frontmatter must contain only static property assignments')
  })

  test('requires a static metadata title', async () => {
    // Given
    const code = "import { md } from 'vite-plugin-mdts'\nexport default md`Body.\n`\n"

    // When
    const compile = compileMarkdownModule({
      code,
      id: '/content/missing-title.md.ts',
      resolveLink: () => Promise.resolve(''),
    })

    // Then
    await expect(compile).rejects.toThrow('expected a static meta.title string')
  })

  test('uses text and hash query parameters for a link import', () => {
    // Given
    const request = {
      hash: 'api',
      path: './reference.md.ts',
      query: 'text=Details&hash=api&link',
      text: 'Details',
    }

    // When
    const parsed = parseLinkRequest('./reference.md.ts?text=Details&hash=api&link')
    const link = formatMarkdownLink({ destination: 'reference.md', request, title: 'Reference' })

    // Then
    expect(parsed).toEqual(request)
    expect(link).toBe('[Details](reference.md#api)')
  })
})
