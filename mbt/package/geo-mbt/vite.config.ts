import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      build: {
        command: 'moon build',
        input: ['moon.mod', '**/*.mbt', '**/*.mbt.md'],
      },
    },
  },
})
