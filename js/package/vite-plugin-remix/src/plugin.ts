import type { Plugin } from 'vite'

export interface RemixPluginOptions {
  /**
   * Path to the browser entry that calls `run()` from `remix/ui`.
   * Default: `app/assets/entry.ts` relative to the project root.
   */
  browserEntry?: string
  /**
   * Output directory for the client build.
   * Default: `dist/client`.
   */
  clientOutDir?: string
  /**
   * Filename for the main browser entry chunk (no hash by default so the
   * SSR HTML can reference a stable URL without consulting a manifest).
   * Default: `assets/entry.js`.
   */
  entryFileNames?: string
}

/**
 * Minimal Vite plugin that wires up the remix browser bundle:
 *
 * - registers a `client` Vite environment whose input is the browser entry
 * - emits one chunk per glob match (e.g. *.client.tsx) so each clientEntry
 *   becomes an independently fetchable script — matching how Remix's asset
 *   server serves component modules
 * - forces `client` to build before any other environment so downstream
 *   server/worker builds can rely on the client manifest existing
 *
 * The plugin intentionally stays Cloudflare-agnostic: pair it with
 * `@cloudflare/vite-plugin` (or any other server-side environment plugin)
 * by listing both in `plugins`.
 */
export function remix(options: RemixPluginOptions = {}): Plugin {
  const browserEntry = options.browserEntry ?? 'app/assets/entry.ts'
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
                input: browserEntry,
                output: {
                  entryFileNames,
                  chunkFileNames: 'assets/[name]-[hash].js',
                  assetFileNames: 'assets/[name]-[hash][extname]',
                },
              },
            },
          },
        },
        builder: {
          async buildApp(builder) {
            const client = builder.environments.client
            if (client) await builder.build(client)
            for (const [name, env] of Object.entries(builder.environments)) {
              if (name === 'client') continue
              await builder.build(env)
            }
          },
        },
      }
    },
  }
}
