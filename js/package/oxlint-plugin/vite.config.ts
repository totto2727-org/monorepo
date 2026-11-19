import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      test: { command: 'vp test' },
    },
  },
  test: {
    dir: 'src',
    setupFiles: ['./src/__fixtures__/rule-tester-setup.ts'],
  },
})
