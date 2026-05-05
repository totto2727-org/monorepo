import { Predicate, String } from 'effect'
import { run } from 'remix/ui'
import type { ImportGlobFunction } from 'vite'

export interface BootOptions {
  /**
   * Map of `moduleUrl` → loader. Keys must match what
   * `resolveClientEntry`'s `href` produces during SSR (typically
   * `/app/<path>/<file>.client.tsx`).
   *
   * The recommended way to populate this is from a project-wide glob:
   *
   * ```ts
   * import.meta.glob('/app/<<asterisk>><<asterisk>>/<<asterisk>>.client.tsx')
   * ```
   *
   * The pattern is left to the consumer because `import.meta.glob` is a
   * compile-time syntax — the bundler must see the literal string in the
   * caller's source to expand it.
   */
  components: ReturnType<ImportGlobFunction>
}

/**
 * Boot the Remix client runtime against a static map of clientEntry loaders.
 *
 * Keeps `loadModule` purely lookup-based — no per-component dynamic
 * `import(moduleUrl)` happens at runtime, so the SSR's `moduleUrl` only
 * acts as a key. Vite resolves the real fetch URL inside each loader
 * closure (Vite source path in dev, hashed chunk path in prod).
 */
export const boot = ({ components }: BootOptions): ReturnType<typeof run> =>
  run({
    async loadModule(moduleUrl: string, exportName: string) {
      const loader = components[moduleUrl]
      if (Predicate.isNullish(loader) || !Predicate.isFunction(loader)) {
        throw new Error(`No client entry registered for ${moduleUrl}`)
      }
      // oxlint-disable-next-line typescript/no-unsafe-call,typescript/no-unsafe-assignment,typescript/ban-types,typescript/no-unsafe-function-type
      const mod: Record<string, Function | Promise<Function>> = await loader()
      const exported = mod[exportName]
      if (Predicate.isNullish(exported)) {
        throw new Error(`Module ${moduleUrl} has no export named "${exportName}"`)
      }
      return exported
    },
    async resolveFrame(src: string, signal?: AbortSignal, target?: string) {
      const headers = new Headers({ accept: 'text/html' })
      if (Predicate.isNotNullish(target) && String.isNonEmpty(target)) {
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
