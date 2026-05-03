import { run } from 'remix/ui'

// Eagerly bundle every clientEntry-bearing module under app/ui so production
// hydration can resolve them by URL without depending on Remix's asset server.
// Keys come back as paths relative to this file ("../ui/counter.tsx"); we
// normalise them to the URLs Remix uses ("/app/ui/counter.tsx" — the value of
// resolveClientEntry's `href` after the legacy "/assets/" prefix is stripped).
const rawModules = import.meta.glob<Record<string, unknown>>('../ui/*.tsx', { eager: true })

const components = Object.fromEntries(
  Object.entries(rawModules).map(([relativePath, mod]) => [relativePath.replace(/^\.\.\//, '/app/'), mod]),
)

run({
  async loadModule(moduleUrl, exportName) {
    const mod = components[moduleUrl]
    if (mod) return mod[exportName]
    // Fallback for any URL not pre-bundled at build time.
    const dynamic = await import(/* @vite-ignore */ moduleUrl)
    return dynamic[exportName]
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
