// vite.config.ts
import adapter from "@hono/vite-dev-server/cloudflare"
import { reactRouter } from "@react-router/dev/vite"
import { cloudflareDevProxy as remixCloudflareDevProxy } from "@react-router/dev/vite/cloudflare"
import serverAdapter from "hono-react-router-adapter/vite"
import { defineConfig } from "vite"
import { getLoadContext } from "./app/types/react-router"

export default defineConfig({
  plugins: [
    remixCloudflareDevProxy(),
    reactRouter(),
    serverAdapter({
      adapter,
      entry: "app/server.ts",
      getLoadContext,
    }),
  ],
})
