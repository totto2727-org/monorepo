/// <reference types="vite/client" />

import { cloudflare } from "@cloudflare/vite-plugin"
import { tanstackStart } from "@tanstack/react-start/plugin/vite"
import viteReact from "@vitejs/plugin-react"
import Icons from "unplugin-icons/vite"
import { defineConfig } from "vite"
import tsconfigPaths from "vite-tsconfig-paths"

export default defineConfig({
  plugins: [
    cloudflare({ viteEnvironment: { name: "ssr" } }),
    tsconfigPaths(),
    tanstackStart({ srcDirectory: "./app" }),
    viteReact({
      babel: {
        plugins: ["babel-plugin-react-compiler"],
      },
    }),
    Icons({
      compiler: "jsx",
      iconCustomizer(_, __, props) {
        props.width = "0.8lh"
        props.height = "0.8lh"
      },
      jsx: "react",
    }),
  ],
})
