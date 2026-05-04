export interface ScriptProps {
  /** Path served by Vite in dev (defaults to `/app/assets/entry.ts`). */
  devSrc?: string
  /** Path served by Workers Assets / static host in prod (defaults to `/assets/entry.js`). */
  prodSrc?: string
}

/**
 * Browser entry `<script>` tag. Picks between the Vite-served source path
 * (dev) and the built chunk path (prod) using Vite's `import.meta.env.DEV`,
 * which is replaced at build time per environment.
 */
export function Script() {
  return ({ devSrc = '/app/assets/entry.ts', prodSrc = '/assets/entry.js' }: ScriptProps) => (
    <script type='module' src={import.meta.env.DEV ? devSrc : prodSrc}></script>
  )
}
