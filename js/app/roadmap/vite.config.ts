import { defineConfig } from 'vite-plus'

export default defineConfig({
  pack: {
    entry: ['src/bin.ts'],
  },
  run: {
    tasks: {
      build: {
        command: 'vp pack',
        input: [{ auto: true }, '!dist/**'],
      },
    },
  },
})
