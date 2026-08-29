import { markdown } from 'vite-plugin-markdown'
import { defineConfig } from 'vite-plus'

export default defineConfig({
  plugins: [
    markdown({
      documents: {
        'guide.md': './content/guide.md.ts',
        'reference.md': './content/reference.md.ts',
      },
    }),
  ],
  run: {
    tasks: {
      build: {
        command: 'vp build',
        input: [{ auto: true }, '!dist/**'],
      },
    },
  },
})
