import { markdown } from 'vite-plugin-markdown'
import { defineConfig } from 'vite-plus'

export default defineConfig({
  plugins: [
    markdown({
      directory: './content',
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
