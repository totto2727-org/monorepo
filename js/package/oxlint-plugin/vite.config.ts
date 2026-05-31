import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      test: { command: 'vp test' },
    },
  },
  test: {
    setupFiles: ['./src/__fixtures__/rule-tester-setup.ts'],
  },
})
