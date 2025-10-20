import { defineConfig } from "tsdown"
import tsconfig from "./tsconfig.json" with { type: "json" }

export default defineConfig({
  dts: {
    sourcemap: true,
  },
  entry: ["src/**/*.{ts,tsx}", "!src/**/*.{test,stories}.{ts,tsx}"],
  inputOptions: {
    jsx: {
      jsxImportSource: tsconfig.compilerOptions.jsxImportSource,
    },
  },
})
