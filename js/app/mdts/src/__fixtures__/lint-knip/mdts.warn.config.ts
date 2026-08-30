import { defineConfig } from '../../config.ts'

export default defineConfig({
  lint: {
    knip: {
      rule: 'warn',
    },
    markdownlint: false,
    textlint: false,
  },
})
