import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      check: {
        command: 'test -z "$(gofmt -l .)"',
        input: [{ auto: true }],
      },
      fix: {
        command: 'go fmt .',
      },
    },
  },
})
