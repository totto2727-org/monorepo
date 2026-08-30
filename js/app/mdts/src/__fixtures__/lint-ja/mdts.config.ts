import { defineConfig } from 'mdts'

export default defineConfig({
  input: './content',
  lint: {
    knip: false,
    markdownlint: false,
    textlint: {
      preset: 'ja',
    },
  },
  output: './dist',
  vite: {
    logLevel: 'silent',
  },
})
