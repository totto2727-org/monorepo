import type { ReactNode } from 'react'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

const getContext_ = () => {
  let context
  return () => {
    context ??= {
      queryClient: new QueryClient(),
    }
    return context
  }
}

export const getContext = getContext_()

export default function TanStackQueryProvider({ children }: { children: ReactNode }) {
  const { queryClient } = getContext()

  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
}
