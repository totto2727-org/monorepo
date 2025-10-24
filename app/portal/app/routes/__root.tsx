import {
  ColorModeScript,
  config,
  ThemeSchemeScript,
  UIProvider,
} from "@package/yamada-ui"
import {
  createRootRoute,
  HeadContent,
  Outlet,
  Scripts,
} from "@tanstack/react-router"
import { TanStackRouterDevtools } from "@tanstack/react-router-devtools"
import { createServerFn } from "@tanstack/react-start"
import { getRequest } from "@tanstack/react-start/server"

const getCookie = createServerFn().handler(() =>
  getRequest().headers.get("Cookie"),
)

export const Route = createRootRoute({
  component: RootComponent,
  head: () => ({
    meta: [
      {
        charSet: "utf-8",
      },
      {
        content: "width=device-width, initial-scale=1",
        name: "viewport",
      },
      {
        title: "Portal",
      },
    ],
  }),
  async loader() {
    return {
      cookie: (await getCookie()) ?? undefined,
    }
  },
})

function RootComponent() {
  const data = Route.useLoaderData()

  return (
    <RootDocument>
      <ColorModeScript defaultValue={config.defaultColorMode} type="cookie" />
      <ThemeSchemeScript
        defaultValue={config.defaultThemeScheme}
        type="cookie"
      />
      <UIProvider config={config} cookie={data.cookie}>
        <Outlet />
      </UIProvider>
      <TanStackRouterDevtools />
    </RootDocument>
  )
}

function RootDocument({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <HeadContent />
      </head>
      <body suppressHydrationWarning>
        {children}
        <Scripts />
      </body>
    </html>
  )
}
