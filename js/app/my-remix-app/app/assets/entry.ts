import { run } from 'remix/ui'

// Project-wide convention: any *.client.tsx is a clientEntry-bearing module.
// Vite expands the glob to one chunk per file at build time; the SSR's
// moduleUrl ("/assets/app/ui/counter.client.tsx#Counter" → after stripping
// "/assets/" → "/app/ui/counter.client.tsx") matches the glob keys directly,
// so no extra normalisation is needed.
const components = import.meta.glob<Record<string, unknown>>('/app/**/*.client.tsx')

run({
  async loadModule(moduleUrl, exportName) {
    const loader = components[moduleUrl]
    if (!loader) {
      throw new Error(`No client entry registered for ${moduleUrl}`)
    }
    const mod = await loader()
    return mod[exportName]
  },
  async resolveFrame(src, signal, target) {
    const headers = new Headers({ accept: 'text/html' })
    if (target) {
      headers.set('x-remix-target', target)
    }

    const response = await fetch(src, {
      credentials: 'same-origin',
      headers,
      signal,
    })
    return response.body ?? response.text()
  },
})
