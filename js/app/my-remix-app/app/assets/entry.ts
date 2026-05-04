import { run } from 'remix/ui'

// Per-component code splitting:
// - dev: each loader is `() => import('../ui/<file>.tsx')`, Vite serves the
//        source on demand from its dev server.
// - prod: vite build emits one chunk per glob match (assets/<name>-<hash>.js)
//        and rewrites the loader to import that chunk URL.
// In both cases the SSR's `moduleUrl` (`/app/ui/<file>.tsx`) only acts as a
// lookup key — the actual fetch URL lives inside the loader closure.
const loaders = import.meta.glob<Record<string, unknown>>('../ui/*.tsx')

const components = Object.fromEntries(
  Object.entries(loaders).map(([rel, loader]) => [rel.replace(/^\.\.\//, '/app/'), loader]),
)

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
