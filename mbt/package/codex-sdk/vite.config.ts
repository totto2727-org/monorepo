import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      build: {
        command: 'moon build --target native src',
        input: ['moon.mod', '**/*.mbt'],
      },
      test: {
        command: 'moon test --target native src',
        input: ['moon.mod', '**/*.mbt'],
      },
    },
  },
})
