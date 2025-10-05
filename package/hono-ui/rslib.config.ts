/// <reference types="@rslib/core/types" />

import { pluginReact } from "@rsbuild/plugin-react"
import { defineConfig } from "@rslib/core"

export default defineConfig({
  lib: [
    {
      bundle: false,
      dts: {
        tsgo: true,
      },
      format: "esm",
      syntax: ["node 18"],
    },
  ],
  plugins: [
    pluginReact({
      swcReactOptions: {
        importSource: "hono/jsx",
      },
    }),
  ],
  source: {
    entry: {
      index: ["./src/**", "!./src/**/*.test.ts"],
    },
    tsconfigPath: "./tsconfig.build.json",
  },
})
