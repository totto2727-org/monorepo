import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      build: {
        command: 'moon build',
        input: [{ auto: true }, '!_build/**'],
      },
      check: {
        command: 'moon check',
        input: [{ auto: true }, '!_build/**'],
      },
      fix: {
        command: 'moon fmt',
        input: [{ auto: true }, '!_build/**'],
      },
      test: {
        command: 'moon test',
        input: [{ auto: true }, '!_build/**'],
      },
    },
  },
})
