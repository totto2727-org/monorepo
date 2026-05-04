/** @jsxRuntime automatic */
/** @jsxImportSource remix/ui */

export interface ScriptProps {
  /**
   * URL served by Vite in dev. Should match the project-relative path
   * Vite resolves to your `clientEntry` source file
   * (e.g. `/app/assets/entry.ts`).
   */
  devSrc: string
  /**
   * URL served by your static host in prod. Should match the plugin's
   * `entryFileNames` setting prefixed with the public asset path
   * (default plugin output: `/assets/entry.js`).
   */
  prodSrc: string
}

/**
 * Client entry `<script>` tag. Picks between the Vite-served source path
 * (dev) and the built chunk path (prod) using Vite's `import.meta.env.DEV`,
 * which is replaced at build time per environment.
 *
 * Both URLs are required so the relationship to the plugin's
 * `clientEntry` / `entryFileNames` settings stays explicit at the call
 * site — the component makes no assumption about your project layout.
 */
export function Script() {
  // `import.meta.env` is injected by Vite. When SSR runs outside Vite
  // (e.g. tsx loading the source directly), it stays undefined and we
  // fall through to the prod URL — which is the correct branch for a
  // built deployment.
  const isDev = (import.meta as ImportMeta & { env?: { DEV?: boolean } }).env?.DEV === true
  return ({ devSrc, prodSrc }: ScriptProps) => (
    <script type='module' src={isDev ? devSrc : prodSrc}></script>
  )
}
