import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      check: {
        command: 'vp check infra/cloudflare',
        cwd: '../..',
      },
      fix: {
        command: 'vp check --fix infra/cloudflare',
        cwd: '../..',
      },
      test: {
        command: 'vp test run --dir infra/cloudflare',
        cwd: '../..',
      },
    },
  },
})
