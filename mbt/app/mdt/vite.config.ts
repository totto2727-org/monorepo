import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      build: {
        command:
          'moon build --target native && mkdir -p dist && cp ../../../_build/native/debug/build/totto2727/mdt/mdt.exe dist/mdt && chmod +x dist/mdt',
        input: ['moon.mod', '**/*.mbt'],
      },
    },
  },
})
