import type { FC, PropsWithChildren } from "hono/jsx"

function HTMX() {
  return (
    <>
      <script
        crossorigin="anonymous"
        integrity="sha384-Akqfrbj/HpNVo8k11SXBb6TlBWmXXlYQrCSqEWmyKJe+hDm3Z/B2WVG4smwBkRVm"
        src="https://cdn.jsdelivr.net/npm/htmx.org@2.0.6/dist/htmx.min.js"
      />
      <script src="https://unpkg.com/hyperscript.org@0.9.14" />
    </>
  )
}

function Tailwind(props: { isProd: boolean; cssPath: string }) {
  return props.isProd ? (
    <link href="/asset/tailwind.css" rel="stylesheet" />
  ) : (
    <link href={props.cssPath} rel="stylesheet" />
  )
}

export const Layout: FC<
  PropsWithChildren & { isProd: boolean; cssPath: string }
> = ({ children, isProd, cssPath }) => (
  <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta content="width=device-width, initial-scale=1.0" name="viewport" />
      <Tailwind cssPath={cssPath} isProd={isProd} />
      <HTMX />
    </head>
    <body>
      <div>{children}</div>
    </body>
  </html>
)
