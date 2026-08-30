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
  lint: {
    markdownlint: {
      config: {
        default: true,
        MD013: false,
      },
    },
  },
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

### Lint configuration

`mdts lint` compiles every `.md.ts` document in memory and validates the generated Markdown through the JavaScript APIs of [`markdownlint`](https://github.com/DavidAnson/markdownlint) and [`textlint`](https://github.com/textlint/textlint). It does not spawn either CLI and does not write or clear the configured output directory.

`lint.markdownlint` accepts `config`, `customRules`, `frontMatter`, `markdownItFactory`, and `noInlineConfig`. The default configuration enables markdownlint's standard rules and treats generated YAML metadata plus the mdts generated-file notice as front matter, so rules validate the authored document rather than mdts boilerplate. Set `markdownlint: false` to disable this engine.

Textlint uses the built-in English preset by default. `preset: 'en'` runs [`slopless`](https://github.com/berelevant-ai/slopless), while `preset: 'ja'` runs [`textlint-rule-preset-ja-technical-writing`](https://github.com/textlint-ja/textlint-rule-preset-ja-technical-writing). The presets are not combined because slopless is English-only and the Japanese technical-writing rules enforce Japanese-specific sentence, punctuation, and character conventions. `presetOptions` overrides individual built-in rules. Set `preset: false` to use only custom rules and presets, or set `textlint: false` to disable the engine.

`lint.textlint` also accepts JavaScript API entries through `rules`, `presets`, `filterRules`, and `plugins`. mdts provides the standard Markdown processor automatically unless a plugin with `pluginId: 'markdown'` is configured. Custom presets use their exported `rules` and `rulesConfig`; `options` overrides individual preset rule settings. Install additional rules, presets, filters, or processors in the consuming project and import their modules from `mdts.config.ts`.

Select and configure the built-in Japanese preset without installing it in the consuming project:

```ts
import { defineConfig } from 'mdts'

export default defineConfig({
  lint: {
    textlint: {
      preset: 'ja',
      presetOptions: {
        'sentence-length': { max: 120 },
      },
    },
  },
})
```

Diagnostics point to the originating `.md.ts` file. Literal Markdown body lines map to their template-literal lines, generated metadata maps to the corresponding metadata expression, and rendered interpolations map to their TypeScript expression.

## Commands

```bash
mdts build
mdts lint
mdts preview
```

`mdts build` writes the generated Markdown files to `output`. `mdts lint` reports markdownlint and textlint diagnostics and exits unsuccessfully when either engine reports an error-severity diagnostic. `mdts preview` starts a Vite development server whose `index.html` lists every generated Markdown document and renders the selected document with `@comark/html`. Documents use normal URL paths such as `/guide.md` and `/reference/api.md`, including direct navigation and browser history.
