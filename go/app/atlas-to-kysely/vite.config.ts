import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      fix: {
        command: 'go fmt .',
      },
    },
  },
})
