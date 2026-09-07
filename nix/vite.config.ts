import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      check: {
        command: "nixfmt --check $(find . -name '*.nix')",
      },
      test: {
        command: 'nix eval --impure --json --file test/my.nix',
      },
      fix: {
        command: "nixfmt $(find . -name '*.nix')",
      },
    },
  },
})
