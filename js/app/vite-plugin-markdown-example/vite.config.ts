import { markdown } from 'vite-plugin-markdown'
import { defineConfig } from 'vite-plus'

import { guide } from './content/guide.md.ts'

export default defineConfig({
  plugins: [markdown({ documents: { 'guide.md': guide } })],
  run: {
    tasks: {
      build: {
        command: 'vp build',
        input: [{ auto: true }, '!dist/**'],
      },
      check: {
        command: 'vp check',
      },
    },
  },
})
