import { defineConfig } from "@rslib/core"

export default defineConfig({
  lib: [
    {
      bundle: false,
      dts: true,
      format: "esm",
      syntax: ["node 18"],
    },
  ],
  source: {
    entry: {
      index: ["./src/**", "!./src/**/*.test.ts"],
    },
    tsconfigPath: "./tsconfig.build.json",
  },
})
