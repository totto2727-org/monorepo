import footnotes from '@comark/html/plugins/footnotes'
import { defineConfig } from 'mdts'

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
