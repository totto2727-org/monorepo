import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      check: {
        command: "nixfmt --check $(find . -name '*.nix')",
      },
      fix: {
        command: "nixfmt $(find . -name '*.nix')",
      },
    },
  },
})
