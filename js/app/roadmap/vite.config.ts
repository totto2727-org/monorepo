import { readFile } from 'node:fs/promises'

import { defineConfig } from 'vite-plus'

export default defineConfig({
  pack: {
    entry: ['src/bin.ts'],
    loader: { '.md': 'text' },
  },
  plugins: [
    {
      async load(id) {
        if (!id.endsWith('.md')) {
          return null
        }
        const source = await readFile(id, 'utf-8')
        return `export default ${JSON.stringify(source)}`
      },
      name: 'roadmap-md-as-text',
    },
  ],
  run: {
    tasks: {
      build: {
        command: 'vp pack',
        input: [{ auto: true }, '!dist/**'],
      },
    },
  },
})
