import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      check: {
        command: 'gofmt -d .',
      },
      fix: {
        command: 'go fmt .',
      },
    },
  },
})
