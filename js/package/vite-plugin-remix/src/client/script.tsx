export interface ScriptProps {
  /**
   * URL served by Vite in dev. Should match the project-relative path
   * Vite resolves to your `browserEntry` source file
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
 * Browser entry `<script>` tag. Picks between the Vite-served source path
 * (dev) and the built chunk path (prod) using Vite's `import.meta.env.DEV`,
 * which is replaced at build time per environment.
 *
 * Both URLs are required so the relationship to the plugin's
 * `browserEntry` / `entryFileNames` settings stays explicit at the call
 * site — the component makes no assumption about your project layout.
 */
export function Script() {
  return ({ devSrc, prodSrc }: ScriptProps) => (
    <script type='module' src={import.meta.env.DEV ? devSrc : prodSrc}></script>
  )
}
