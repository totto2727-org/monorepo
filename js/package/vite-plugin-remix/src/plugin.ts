import type { Plugin } from 'vite'

export interface RemixPluginOptions {
  /**
   * Path to the client entry that calls `run()` from `remix/ui`,
   * relative to the project root. Required — the plugin makes no
   * assumption about your directory layout.
   */
  clientEntry: string
  /**
   * Output directory for the client build.
   * Default: `dist/client`.
   */
  clientOutDir?: string
  /**
   * Filename for the main client entry chunk (no hash by default so the
   * SSR HTML can reference a stable URL without consulting a manifest).
   * Default: `assets/entry.js`.
   */
  entryFileNames?: string
}

/**
 * Minimal Vite plugin that wires up the remix client bundle:
 *
 * - registers a `client` Vite environment whose input is the client entry
 * - emits one chunk per glob match (e.g. *.client.tsx) so each clientEntry
 *   becomes an independently fetchable script — matching how Remix's asset
 *   server serves component modules
 *
 * Build ordering is left to Vite's default `builder` — no environment
 * consumes the client manifest in the current architecture (clientEntry
 * hrefs work as in-memory lookup keys, not real fetch URLs). If a
 * downstream environment ever needs the manifest, supply your own
 * `builder.buildApp` to enforce client-first ordering.
 */
export function remix(options: RemixPluginOptions): Plugin {
  const { clientEntry } = options
  const clientOutDir = options.clientOutDir ?? 'dist/client'
  const entryFileNames = options.entryFileNames ?? 'assets/entry.js'

  return {
    name: 'plugin-remix',
    config() {
      return {
        environments: {
          client: {
            build: {
              manifest: true,
              outDir: clientOutDir,
              rollupOptions: {
                input: clientEntry,
                output: {
                  entryFileNames,
                  chunkFileNames: 'assets/[name]-[hash].js',
                  assetFileNames: 'assets/[name]-[hash][extname]',
                },
              },
            },
          },
        },
      }
    },
  }
}
