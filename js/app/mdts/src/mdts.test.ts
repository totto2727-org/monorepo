import { readFile, readdir, rm } from 'node:fs/promises'
import { fileURLToPath } from 'node:url'

import { createHtmlRenderer } from '@comark/html'
import { Effect, Predicate } from 'effect'
import { FetchHttpClient, HttpClient } from 'effect/unstable/http'
import { markdownDocumentsId } from 'vite-plugin-mdts'
import { afterEach, beforeEach, describe, expect, test } from 'vite-plus/test'

import { buildMarkdown } from './build.ts'
import { createMarkdownPreview } from './preview.ts'

const projectRoot = fileURLToPath(new URL('__fixtures__/basic/', import.meta.url))
const outputDirectory = fileURLToPath(new URL('__fixtures__/basic/dist/', import.meta.url))

const cleanOutput = (): Promise<void> => rm(outputDirectory, { force: true, recursive: true })

const moduleSource = (value: unknown): string => {
  if (!Predicate.isObject(value)) {
    throw new TypeError('expected a Markdown module')
  }
  const source = Reflect.get(value, 'default')
  if (!Predicate.isString(source)) {
    throw new TypeError('expected a Markdown default export')
  }
  return source
}

beforeEach(cleanOutput)
afterEach(cleanOutput)

describe('mdts', () => {
  test('builds Markdown assets without loading vite.config.ts', async () => {
    // When
    await buildMarkdown({ root: projectRoot })

    // Then
    const guide = await readFile(`${outputDirectory}/guide.md`, 'utf-8')
    const reference = await readFile(`${outputDirectory}/reference/api.md`, 'utf-8')
    const outputs = await readdir(outputDirectory, { recursive: true })

    expect(guide).toBe('# Guide\n\nRead the [API Reference](reference/api.md).\n')
    expect(reference).toBe('# API Reference\n\nThe API is ready.\n')
    expect(outputs).not.toContain('index.html')
    expect(outputs.every((fileName) => !fileName.endsWith('.js'))).toBe(true)
  })

  test('loads preview documents for Comark HTML rendering', async () => {
    // Given
    const server = await createMarkdownPreview({ root: projectRoot })

    try {
      // When
      const loaded = await server.ssrLoadModule(markdownDocumentsId)
      const modules: unknown = loaded.default
      if (!Predicate.isObject(modules)) {
        throw new TypeError('expected the Markdown document collection')
      }
      const renderHtml = createHtmlRenderer()
      const guide = moduleSource(Reflect.get(modules, '/content/guide.md.ts'))
      const reference = moduleSource(Reflect.get(modules, '/content/reference/api.md.ts'))

      // Then
      await expect(renderHtml(guide)).resolves.toBe(
        '<h1 id="guide">Guide</h1>\n<p>Read the <a href="reference/api.md">API Reference</a>.</p>',
      )
      await expect(renderHtml(reference)).resolves.toBe(
        '<h1 id="api-reference">API Reference</h1>\n<p>The API is ready.</p>',
      )
    } finally {
      await server.close()
    }
  })

  test('serves preview HTML at normal document paths', async () => {
    // Given
    const server = await createMarkdownPreview({ root: projectRoot })

    try {
      await server.listen()
      const previewUrl = server.resolvedUrls?.local[0]
      if (Predicate.isNullish(previewUrl)) {
        throw new TypeError('expected a preview URL')
      }

      // When
      const requestDocument = Effect.gen(function* () {
        const client = yield* HttpClient.HttpClient
        const response = yield* client.get(new URL('/reference/api.md', previewUrl).href)
        return { body: yield* response.text, status: response.status }
      }).pipe(Effect.provide(FetchHttpClient.layer))
      // oxlint-disable-next-line rules/no-effect-runtime-run -- Test boundary executes one preview HTTP request workflow.
      const response = await Effect.runPromise(requestDocument)

      // Then
      expect(response.status).toBe(200)
      expect(response.body).toContain('<title>mdts preview</title>')
      expect(response.body).toContain('github-markdown-css')
      expect(response.body).toContain('katex.min.css')
    } finally {
      await server.close()
    }
  })

  test('applies configured Comark plugins to preview documents', async () => {
    // Given
    const server = await createMarkdownPreview({ root: projectRoot })

    try {
      await server.listen()
      const previewUrl = server.resolvedUrls?.local[0]
      if (Predicate.isNullish(previewUrl)) {
        throw new TypeError('expected a preview URL')
      }

      // When
      const requestDocuments = Effect.gen(function* () {
        const client = yield* HttpClient.HttpClient
        const response = yield* client.get(new URL('/__mdts/documents', previewUrl).href)
        return { body: yield* response.text, status: response.status }
      }).pipe(Effect.provide(FetchHttpClient.layer))
      // oxlint-disable-next-line rules/no-effect-runtime-run -- Test boundary executes one preview HTTP request workflow.
      const response = await Effect.runPromise(requestDocuments)
      const documents: unknown = JSON.parse(response.body)
      if (!Array.isArray(documents)) {
        throw new TypeError('expected preview documents')
      }
      const previewDocuments = documents as readonly unknown[]
      const pluginDocument = previewDocuments.find(
        (document) => Predicate.isObject(document) && Reflect.get(document, 'fileName') === 'plugins.md',
      )
      if (!Predicate.isObject(pluginDocument)) {
        throw new TypeError('expected the plugin preview document')
      }
      const html: unknown = Reflect.get(pluginDocument, 'html')

      // Then
      expect(response.status).toBe(200)
      expect(html).toBeTypeOf('string')
      expect(html).toContain('footnote')
      expect(html).toContain('class="markdown-alert markdown-alert-warning"')
    } finally {
      await server.close()
    }
  })
})
