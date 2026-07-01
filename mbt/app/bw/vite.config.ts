import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      build: {
        command:
          'moon build --target native && mkdir -p dist && cp ../../../_build/native/debug/build/totto2727/bw/bw.exe dist/bw && chmod +x dist/bw',
        input: ['moon.mod', '**/*.mbt'],
      },
    },
  },
})
