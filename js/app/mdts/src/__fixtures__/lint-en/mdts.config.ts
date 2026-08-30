import { defineConfig } from 'mdts'

export default defineConfig({
  input: './content',
  lint: {
    knip: false,
  },
  output: './dist',
  vite: {
    logLevel: 'silent',
  },
})
