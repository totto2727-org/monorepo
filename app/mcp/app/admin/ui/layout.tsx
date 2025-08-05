import type { PropsWithChildren } from "hono/jsx"
import { Htmx } from "./layout/htmx.js"
import { Tailwind } from "./layout/tailwind.js"

export function Layout({ children }: PropsWithChildren) {
  return (
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta content="width=device-width, initial-scale=1.0" name="viewport" />
        <Tailwind />
        <Htmx />
      </head>
      <body>
        <div>{children}</div>
      </body>
    </html>
  )
}
