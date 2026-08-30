import { defineConfig } from '../../config.ts'

export default defineConfig({
  lint: {
    knip: {
      ignoreFiles: ['content/nested/orphan.md.ts'],
    },
    markdownlint: false,
    textlint: false,
  },
})
