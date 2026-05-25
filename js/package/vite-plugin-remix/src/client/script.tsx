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
 *
 * Intended for SSR that itself runs through Vite (so `import.meta.env`
 * gets replaced). When SSR runs outside Vite (e.g. tsx loading the
 * source directly), emit a plain `<script>` pointing at the built
 * entry instead.
 */
export const Script =
  () =>
  // oxlint-disable-next-line rules/no-jsx-script-tag -- This component exists solely to emit a bare HTML <script> tag for Vite-powered SSR entry injection
  ({ devSrc, prodSrc }: ScriptProps) => <script type='module' src={import.meta.env.DEV ? devSrc : prodSrc}></script>
