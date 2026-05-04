// Browser entry script tag. The URL switches between the Vite-served source
// path (dev) and the built Workers-Assets chunk path (prod) via Vite's
// import.meta.env.DEV flag, replaced at build time.
export function Script() {
  return () => (
    <script type='module' src={import.meta.env.DEV ? '/app/assets/entry.ts' : '/assets/entry.js'}></script>
  )
}
