import type { FC, PropsWithChildren } from "hono/jsx"

function HTMX() {
  return (
    <>
      <script
        crossorigin="anonymous"
        integrity="sha384-Akqfrbj/HpNVo8k11SXBb6TlBWmXXlYQrCSqEWmyKJe+hDm3Z/B2WVG4smwBkRVm"
        src="https://cdn.jsdelivr.net/npm/htmx.org@2.0.6/dist/htmx.min.js"
      ></script>
      <script src="https://unpkg.com/hyperscript.org@0.9.14"></script>
    </>
  )
}

function Tailwind(props: { isProd: boolean; css: string }) {
  return props.isProd ? (
    <link href="/asset/tailwind.css" rel="stylesheet" />
  ) : (
    <>
      <link
        href="https://cdn.jsdelivr.net/npm/daisyui@5"
        rel="stylesheet"
        type="text/css"
      />
      <link
        href="https://cdn.jsdelivr.net/npm/daisyui@5/themes.css"
        rel="stylesheet"
        type="text/css"
      />
      <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
      <style
        // biome-ignore lint/security/noDangerouslySetInnerHtml: required
        dangerouslySetInnerHTML={{ __html: props.css }}
        // @ts-expect-error
        type="text/tailwindcss"
      ></style>
    </>
  )
}

export const Layout: FC<
  PropsWithChildren & { isProd: boolean; css: string }
> = ({ children, isProd, css }) => {
  return (
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta content="width=device-width, initial-scale=1.0" name="viewport" />
        <Tailwind css={css} isProd={isProd} />
        <HTMX />
      </head>
      <body>
        <div>{children}</div>
      </body>
    </html>
  )
}
