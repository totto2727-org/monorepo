import { routeTree } from '#app/routeTree.gen.ts'
import { RouterProvider, createRouter } from '@tanstack/react-router'
import { Predicate } from '@totto2727/fp/effect'
import { StrictMode } from 'react'
import ReactDOM from 'react-dom/client'

// Create a new router instance
const router = createRouter({
  basepath: '/app',
  routeTree,
})

// Register the router instance for type safety
declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}

const rootElement = document.querySelector('#root')
if (Predicate.isNotNullable(rootElement?.innerHTML)) {
  const root = ReactDOM.createRoot(rootElement)
  root.render(
    <StrictMode>
      <RouterProvider router={router} />
    </StrictMode>,
  )
}
