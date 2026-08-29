import { createHtmlRenderer } from '@comark/html'
import { Predicate, String } from 'effect'
import { markdownDocumentsId } from 'vite-plugin-mdts'
import { createServer, normalizePath } from 'vite-plus'
import type { Plugin, ViteDevServer } from 'vite-plus'

import { resolveMdtsViteConfig } from './build.ts'
import { loadMdtsConfig } from './config.ts'

const documentsEndpoint = '/__mdts/documents'
const previewClientId = '/@mdts/client'
const resolvedPreviewClientId = '\0mdts:preview-client'

interface MdtsPreviewOptions {
  readonly configFile?: string
  readonly root: string
}

interface DocumentModule {
  readonly default?: unknown
}

interface PreviewDocument {
  readonly fileName: string
  readonly html: string
}

const indexHtml = `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="color-scheme" content="light dark" />
    <link rel="icon" href="data:," />
    <title>mdts preview</title>
    <style>
      :root { font-family: ui-sans-serif, system-ui, sans-serif; color: #18212f; background: #f6f7f9; }
      * { box-sizing: border-box; }
      body { margin: 0; }
      .layout { display: grid; grid-template-columns: minmax(15rem, 22rem) minmax(0, 1fr); min-height: 100vh; }
      nav { padding: 2rem 1.5rem; border-right: 1px solid #d9dee7; background: #fff; }
      nav h1 { margin: 0 0 1.5rem; font-size: 1.25rem; }
      nav ul { display: grid; gap: 0.35rem; padding: 0; margin: 0; list-style: none; }
      nav a { display: block; padding: 0.65rem 0.75rem; border-radius: 0.5rem; color: inherit; text-decoration: none; overflow-wrap: anywhere; }
      nav a:hover, nav a[aria-current="page"] { background: #edf2ff; color: #2849a8; }
      main { width: min(100%, 60rem); padding: 3rem clamp(1.5rem, 5vw, 5rem); }
      article { line-height: 1.7; }
      article img { max-width: 100%; }
      article pre { overflow: auto; padding: 1rem; border-radius: 0.5rem; background: #1f2937; color: #f9fafb; }
      article code { font-family: ui-monospace, monospace; }
      .empty, .error { padding: 1rem; border-radius: 0.5rem; background: #fff; }
      .error { color: #b42318; }
      @media (max-width: 760px) { .layout { grid-template-columns: 1fr; } nav { border-right: 0; border-bottom: 1px solid #d9dee7; } main { padding-top: 2rem; } }
      @media (prefers-color-scheme: dark) {
        :root { color: #e6eaf0; background: #111827; }
        nav { background: #18212f; border-color: #344054; }
        nav a:hover, nav a[aria-current="page"] { background: #263b6a; color: #dbe6ff; }
        .empty, .error { background: #18212f; }
      }
    </style>
  </head>
  <body>
    <div id="app" class="layout"><main><p>Loading Markdown documents…</p></main></div>
    <script type="module" src="${previewClientId}"></script>
  </body>
</html>
`

const previewClientSource = `const endpoint = ${JSON.stringify(documentsEndpoint)}
const app = document.querySelector('#app')
let documents = []

const selectedFileName = () => {
  const requested = window.location.pathname
    .slice(1)
    .split('/')
    .map(decodeURIComponent)
    .join('/')
  return documents.some((document) => document.fileName === requested) ? requested : documents[0]?.fileName
}

const documentPath = (fileName) =>
  '/' + fileName.split('/').map(encodeURIComponent).join('/')

const navigateToDocument = (event) => {
  const link = event.target instanceof Element ? event.target.closest('a') : undefined
  const href = link?.getAttribute('href')
  if (!href || href.startsWith('#') || /^[a-z]+:/u.test(href)) return

  const target = new URL(href, window.location.href)
  const fileName = target.pathname.slice(1).split('/').map(decodeURIComponent).join('/')
  if (documents.some((document) => document.fileName === fileName)) {
    event.preventDefault()
    window.history.pushState({}, '', documentPath(fileName))
    render()
  }
}

const render = () => {
  const selected = selectedFileName()
  if (!selected) {
    app.innerHTML = '<main><p class="empty">No .md.ts documents were found.</p></main>'
    return
  }

  const navigation = document.createElement('nav')
  const heading = document.createElement('h1')
  heading.textContent = 'Markdown documents'
  navigation.append(heading)

  const list = document.createElement('ul')
  for (const entry of documents) {
    const item = document.createElement('li')
    const link = document.createElement('a')
    link.href = documentPath(entry.fileName)
    link.textContent = entry.fileName
    if (entry.fileName === selected) link.setAttribute('aria-current', 'page')
    item.append(link)
    list.append(item)
  }
  navigation.append(list)
  navigation.addEventListener('click', navigateToDocument)

  const main = document.createElement('main')
  const article = document.createElement('article')
  article.innerHTML = documents.find((document) => document.fileName === selected).html
  article.addEventListener('click', navigateToDocument)
  main.append(article)
  app.replaceChildren(navigation, main)
}

const load = async () => {
  try {
    const response = await fetch(endpoint, { cache: 'no-store' })
    if (!response.ok) throw new Error(await response.text())
    documents = await response.json()
    render()
  } catch (error) {
    app.innerHTML = '<main><pre class="error"></pre></main>'
    app.querySelector('.error').textContent = error instanceof Error ? error.message : String(error)
  }
}

window.addEventListener('popstate', render)
await load()
`

const markdownSource = (value: unknown): string | undefined => {
  if (Predicate.isString(value)) {
    return value
  }
  if (Predicate.isObject(value)) {
    const source = (value as DocumentModule).default
    return Predicate.isString(source) ? source : undefined
  }
  return undefined
}

const outputFileName = (modulePath: string, input: string): string | undefined => {
  const normalizedPath = normalizePath(modulePath)
  const prefix = String.isEmpty(input) ? '/' : `/${input}/`
  if (!normalizedPath.startsWith(prefix) || !normalizedPath.endsWith('.md.ts')) {
    return undefined
  }
  return `${normalizedPath.slice(prefix.length, -'.md.ts'.length)}.md`
}

const previewPlugin = (input: string): Plugin => {
  const renderHtml = createHtmlRenderer()

  return {
    configureServer(server) {
      server.middlewares.use((request, response, next) => {
        void (async () => {
          try {
            const url = new URL(request.url ?? '/', 'http://mdts.local')
            if (url.pathname === '/' || url.pathname === '/index.html' || url.pathname.endsWith('.md')) {
              const html = await server.transformIndexHtml(url.pathname, indexHtml)
              response.statusCode = 200
              response.setHeader('Content-Type', 'text/html; charset=utf-8')
              response.end(html)
              return
            }

            if (url.pathname !== documentsEndpoint) {
              next()
              return
            }

            const loaded = await server.ssrLoadModule(markdownDocumentsId)
            const modules: unknown = loaded.default
            if (!Predicate.isObject(modules) || Array.isArray(modules)) {
              throw new TypeError('vite-plugin-mdts returned an invalid document collection')
            }

            const documents = await Promise.all(
              Object.entries(modules).map(async ([modulePath, module]): Promise<PreviewDocument | undefined> => {
                const fileName = outputFileName(modulePath, input)
                const source = markdownSource(module)
                if (Predicate.isNullish(fileName) || Predicate.isNullish(source)) {
                  return undefined
                }
                return { fileName, html: await renderHtml(source) }
              }),
            )
            const responseBody = documents
              .flatMap((document) => (Predicate.isNullish(document) ? [] : [document]))
              .toSorted((left, right) => left.fileName.localeCompare(right.fileName))

            response.statusCode = 200
            response.setHeader('Cache-Control', 'no-store')
            response.setHeader('Content-Type', 'application/json; charset=utf-8')
            response.end(JSON.stringify(responseBody))
          } catch (error) {
            next(error)
          }
        })()
      })
    },
    handleHotUpdate(context) {
      const sourceDirectory = String.isEmpty(input)
        ? context.server.config.root
        : `${context.server.config.root}/${input}`
      const fileName = normalizePath(context.file)
      if (fileName.startsWith(`${normalizePath(sourceDirectory)}/`) && fileName.endsWith('.md.ts')) {
        context.server.ws.send({ type: 'full-reload' })
        return []
      }
      return context.modules
    },
    load(id) {
      return id === resolvedPreviewClientId ? previewClientSource : undefined
    },
    name: 'mdts-preview',
    resolveId(id) {
      return id === previewClientId ? resolvedPreviewClientId : undefined
    },
  }
}

export const createMarkdownPreview = async (options: MdtsPreviewOptions): Promise<ViteDevServer> => {
  const config = await loadMdtsConfig({ command: 'serve', ...options })
  return await createServer(
    resolveMdtsViteConfig(config, {
      appType: 'custom',
      plugins: [previewPlugin(config.input)],
    }),
  )
}
