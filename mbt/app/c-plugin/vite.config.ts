import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      build: {
        command:
          'moon build --target native && mkdir -p dist && cp ../../../_build/native/debug/build/totto2727/c-plugin/c-plugin.exe dist/c-plugin && chmod +x dist/c-plugin',
        input: ['moon.mod', '**/*.mbt'],
      },
    },
  },
})
