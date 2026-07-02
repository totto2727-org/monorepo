import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      build: {
        command: 'moon build --target native',
        input: ['moon.mod', '**/*.mbt'],
      },
    },
  },
})
