import { TanStackDevtools } from '@tanstack/react-devtools'
import type { QueryClient } from '@tanstack/react-query'
import { ReactQueryDevtoolsPanel } from '@tanstack/react-query-devtools'
import { HeadContent, Scripts, createRootRouteWithContext } from '@tanstack/react-router'
import { TanStackRouterDevtoolsPanel } from '@tanstack/react-router-devtools'
import { Predicate } from 'effect'

import { getLocale } from '#@/feature/i18n/share.ts'

import TanStackQueryProvider from '../feature/share/lib/tanstack-query/provider.tsx'

import appCss from '../styles.css?url'

const RootDocument = ({ children }: { children: React.ReactNode }) => (
  <html lang={getLocale()} suppressHydrationWarning data-mode='dark'>
    <head>
      <HeadContent />
    </head>
    <body>
      <TanStackQueryProvider>
        {children}
        <TanStackDevtools
          config={{
            position: 'bottom-right',
          }}
          plugins={[
            {
              name: 'Tanstack Router',
              render: <TanStackRouterDevtoolsPanel />,
            },
            {
              name: 'Tanstack Query',
              render: <ReactQueryDevtoolsPanel />,
            },
          ]}
        />
      </TanStackQueryProvider>
      <Scripts />
    </body>
  </html>
)

interface RouterContext {
  queryClient: QueryClient
}

export const Route = createRootRouteWithContext<RouterContext>()({
  beforeLoad: () => {
    if (Predicate.isNotNullish(document)) {
      document.documentElement.setAttribute('lang', getLocale())
    }
  },

  head: () => ({
    links: [
      {
        href: appCss,
        rel: 'stylesheet',
      },
    ],
    meta: [
      {
        charSet: 'utf-8',
      },
      {
        content: 'width=device-width, initial-scale=1',
        name: 'viewport',
      },
      {
        title: 'TanStack Start Starter',
      },
    ],
  }),
  shellComponent: RootDocument,
})
