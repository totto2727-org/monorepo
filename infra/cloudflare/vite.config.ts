import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      check: { command: 'vp check' },
      fix: { command: 'vp check --fix' },
    },
  },
})
