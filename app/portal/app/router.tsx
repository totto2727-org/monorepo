import { createRouter } from "@tanstack/react-router"
// biome-ignore lint/suspicious/noTsIgnore: required
// @ts-ignore
import { routeTree } from "./routeTree.gen.ts"

export function getRouter() {
  const router = createRouter({
    routeTree,
    scrollRestoration: true,
  })

  return router
}

declare module "@tanstack/react-router" {
  // biome-ignore lint/style/useConsistentTypeDefinitions: Need override
  interface Register {
    router: ReturnType<typeof getRouter>
  }
}
