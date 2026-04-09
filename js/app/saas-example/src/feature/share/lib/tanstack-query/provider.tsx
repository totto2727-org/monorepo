import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import type { ReactNode } from 'react'

const getContext_ = () => {
  // oxlint-disable-next-line rules/no-let -- lazy initialization in closure
  let context: { queryClient: QueryClient }
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
