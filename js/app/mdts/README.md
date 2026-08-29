# mdts CLI

`mdts` builds `.md.ts` documents with Vite+ and serves an HTML preview rendered by Comark.

## Configuration

Create `mdts.config.ts` in the project root. Both fields are optional and default to `content` and `dist`.

```ts
import { defineConfig } from 'mdts'

export default defineConfig({
  input: './content',
  output: './dist',
  vite: {
    server: {
      port: 4173,
    },
  },
})
```

The CLI loads only `mdts.config.ts`. It passes `configFile: false` to Vite+, so an existing `vite.config.ts` is ignored. The optional `vite` object is merged into the CLI defaults, while the project root, Markdown input, output directory, internal plugins, and disabled Vite config discovery remain owned by `mdts`.

## Commands

```bash
mdts build
mdts preview
```

`mdts build` writes the generated Markdown files to `output`. `mdts preview` starts a Vite development server whose `index.html` lists every generated Markdown document and renders the selected document with `@comark/html`.
