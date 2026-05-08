import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      check: {
        command: 'gofmt -d .',
        input: [{ auto: true }],
      },
      fix: {
        command: 'go fmt .',
      },
    },
  },
})
