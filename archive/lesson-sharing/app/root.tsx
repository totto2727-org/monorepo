import {
  ColorModeScript,
  createColorModeManager,
  createThemeSchemeManager,
  ThemeSchemeScript,
  UIProvider,
} from "@yamada-ui/react"
import { Links, Meta, Outlet, Scripts, ScrollRestoration } from "react-router"
import { config, theme } from "#@/feature/theme.js"
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
  const themeSchemeManager = createThemeSchemeManager(
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
        <ColorModeScript
          initialColorMode={config.initialColorMode}
          nonce="yamada-ui"
          type="cookie"
        />
        <ThemeSchemeScript
          initialThemeScheme={config.initialThemeScheme}
          nonce="yamada-ui"
          type="cookie"
        />
        <UIProvider
          colorModeManager={colorModeManager}
          config={config}
          theme={theme}
          themeSchemeManager={themeSchemeManager}
        >
          <Outlet />
        </UIProvider>
        <ScrollRestoration />
        <Scripts />
      </body>
    </html>
  )
}
