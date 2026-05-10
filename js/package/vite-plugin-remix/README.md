# vite-plugin-remix

A minimal plugin for handling Remix v3 client bundling + hydration with Vite.

Reference: For SSR in arbitrary frameworks, see [`hono-remix-middleware`](../hono-remix-middleware/README.md).

## What it does?

- Registers a Vite `client` environment and builds a client entry from a single file
- Forces rollup to emit each `*.client.tsx` as an **individual chunk** (per-component lazy loading equivalent to Remix's asset server)
- A `<Script>` component that switches the script URL between dev / prod
- A `boot()` helper to pass `import.meta.glob` loaders into `remix/ui#run`

## Installation

```sh
pnpm add -D vite-plugin-remix
# peer: vite, remix
```

## Quick Start

The directory specified as `app` below can be set to any arbitrary directory including `src`.

### `vite.config.ts`

```ts
import { remix } from 'vite-plugin-remix'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' })],
})
```

### `app/assets/entry.ts` (client entry)

```ts
import { boot } from 'vite-plugin-remix/client'

boot({
  components: import.meta.glob('/app/**/*.client.tsx'),
})
```

### `<Script>` component (inserted into SSR HTML)

- Because the URL changes per project, it must be explicitly set
- `devSrc` = project-relative URL where the Vite dev server resolves `clientEntry`
- `prodSrc` = public URL of the built entry (corresponds to the plugin's `entryFileNames`)

`<Script>` switches between the two via `import.meta.env.DEV`:

| Environment         | Output                                                                                        |
| ------------------- | --------------------------------------------------------------------------------------------- |
| dev (`vite dev`)    | `<script type="module" src={devSrc}></script>` — Vite dev server serves transformed source TS |
| prod (`vite build`) | `<script type="module" src={prodSrc}></script>` — Static distribution of the built chunk      |

```tsx
import { Script } from 'vite-plugin-remix/client'

export function Document() {
  return ({ children }) => (
    <html>
      <head>...</head>
      <body>
        {children}
        <Script devSrc='/app/assets/entry.ts' prodSrc='/assets/entry.js' />
      </body>
    </html>
  )
}
```

## Options

```ts
remix({
  clientEntry: 'app/assets/entry.ts', // relative path to the client entry
  clientOutDir: 'dist/client', // build output directory
  entryFileNames: 'assets/entry.js', // entry chunk filename (no hash by default)
})
```

| Option           | Default           | Purpose                                                                                                                                                                                                                                                            |
| ---------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `clientEntry`    | **Required**      | rollup input. The file that calls `boot()`.                                                                                                                                                                                                                        |
| `clientOutDir`   | `dist/client`     | Build output destination for the client environment. The directory to point a static host (e.g. `serveStatic`) to.                                                                                                                                                 |
| `entryFileNames` | `assets/entry.js` | Output filename for the main entry. Default is a fixed name without a hash, so it can be referenced from SSR HTML without a manifest. For cache busting, change to `assets/entry.[hash].js` etc. and separately set up a route to read the Vite manifest from SSR. |

`chunkFileNames` / `assetFileNames` are fixed with hashes (for component chunks, etc.).

## Build Output

```text
dist/client/
├── .vite/manifest.json                 # For cache busting / dynamic resolution (consumers may optionally reference)
├── assets/
│   ├── entry.js                        # main entry (fixed name)
│   ├── counter.client-XXX.js           # one chunk per *.client.tsx
│   ├── todo.client-XXX.js
│   └── css-mixin-XXX.js                # shared chunk
```

## License

MIT
