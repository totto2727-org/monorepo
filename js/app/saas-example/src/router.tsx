import { createRouter as createTanStackRouter } from '@tanstack/react-router'

import { getContext } from './feature/share/lib/tanstack-query/provider.tsx'
import { routeTree } from './routeTree.gen.ts'

export const getRouter = () => {
  const router = createTanStackRouter({
    context: getContext(),
    defaultPreload: 'intent',
    defaultPreloadStaleTime: 0,
    routeTree,
    scrollRestoration: true,
  })

  return router
}

declare module '@tanstack/react-router' {
  interface Register {
    router: ReturnType<typeof getRouter>
  }
}
