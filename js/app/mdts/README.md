# mdts CLI

`mdts` uses Effect's CLI API to build `.md.ts` documents with Vite+ and serve an HTML preview rendered by Comark.

## Configuration

Install `mdts` as the only project dependency. It re-exports the Markdown authoring API from `vite-plugin-mdts` and the supported Comark preview plugins, while keeping their packages as internal runtime dependencies.

Enable typed `?link` imports through the mdts client types:

```json
{
  "compilerOptions": {
    "types": ["mdts/client"]
  }
}
```

Create `mdts.config.ts` in the project root. Both fields are optional and default to `content` and `dist`.

```ts
import { defineConfig } from 'mdts'
import { footnotes, math, Math, mermaid, Mermaid, shiki } from 'mdts/comark'

export default defineConfig({
  input: './content',
  output: './dist',
  preview: {
    comark: {
      components: { Math, Mermaid },
      plugins: [footnotes(), math(), mermaid(), shiki()],
    },
  },
  vite: {
    server: {
      port: 4173,
    },
  },
})
```

Markdown modules also import their authoring helpers from `mdts`:

```ts
import { defineNote, md, noteBody, noteRef } from 'mdts'
import type { MarkdownMetadata } from 'mdts'
```

The CLI loads only `mdts.config.ts`. It passes `configFile: false` to Vite+, so an existing `vite.config.ts` is ignored. The optional `vite` object is merged into the CLI defaults, while the project root, Markdown input, output directory, internal plugins, and disabled Vite config discovery remain owned by `mdts`.

## Commands

```bash
mdts build
mdts preview
```

`mdts build` writes the generated Markdown files to `output`. `mdts preview` starts a Vite development server whose `index.html` lists every generated Markdown document and renders the selected document with `@comark/html`. Documents use normal URL paths such as `/guide.md` and `/reference/api.md`, including direct navigation and browser history.
