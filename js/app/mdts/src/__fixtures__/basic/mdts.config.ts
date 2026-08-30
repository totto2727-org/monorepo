import { defineConfig } from 'mdts'
import { footnotes } from 'mdts/comark'

export default defineConfig({
  input: './content',
  output: './dist',
  preview: {
    comark: {
      plugins: [footnotes()],
    },
  },
  vite: {
    logLevel: 'silent',
    server: {
      port: 0,
      strictPort: true,
    },
  },
})
