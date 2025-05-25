import {
  ColorModeScript,
  createColorModeManager,
  defaultConfig,
  UIProvider,
} from "@yamada-ui/react"
import { Links, Meta, Outlet, Scripts, ScrollRestoration } from "react-router"
import type { Route } from "./+types/root"

export const loader = async (args: Route.LoaderArgs) => {
  return {
    cookies: args.request.headers.get("Cookie") ?? "",
  }
}

export default function Root(props: Route.ComponentProps) {
  const colorModeManager = createColorModeManager(
    "ssr",
    props.loaderData.cookies,
  )

  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta content="width=device-width, initial-scale=1" name="viewport" />
        <Meta />
        <Links />
      </head>
      <body>
        <ColorModeScript initialColorMode={defaultConfig.initialColorMode} />
        <UIProvider colorModeManager={colorModeManager}>
          <Outlet />
        </UIProvider>
        <ScrollRestoration />
        <Scripts />
      </body>
    </html>
  )
}
