import {
  createRootRoute,
  HeadContent,
  Outlet,
  Scripts,
} from "@tanstack/react-router"
import { TanStackRouterDevtools } from "@tanstack/react-router-devtools"
import { createServerFn } from "@tanstack/react-start"
import { getRequest } from "@tanstack/react-start/server"
import {
  ColorModeScript,
  createColorModeManager,
  UIProvider,
} from "@yamada-ui/react"

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
  const colorModeManager = createColorModeManager("ssr", data.cookie)

  return (
    <RootDocument>
      <ColorModeScript
        initialColorMode="dark"
        nonce="totto2727"
        type="cookie"
      />
      <UIProvider colorModeManager={colorModeManager}>
        <Outlet />
      </UIProvider>
      <TanStackRouterDevtools />
    </RootDocument>
  )
}

function RootDocument({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <HeadContent />
      </head>
      <body>
        {children}
        <Scripts />
      </body>
    </html>
  )
}
