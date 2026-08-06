import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      build: {
        command: 'go build ./...',
      },
      check: {
        command: 'golangci-lint run ./...',
      },
      fix: {
        command: 'golangci-lint run --fix ./...',
      },
      test: {
        command: 'go test -race -shuffle=on -count=1 ./...',
      },
    },
  },
})
