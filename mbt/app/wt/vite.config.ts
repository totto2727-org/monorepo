import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      build: {
        command:
          'moon build --target native && mkdir -p dist && cp ../../../_build/native/debug/build/totto2727/wt/wt.exe dist/wt && chmod +x dist/wt',
        input: ['moon.mod', '**/*.mbt'],
      },
    },
  },
})
