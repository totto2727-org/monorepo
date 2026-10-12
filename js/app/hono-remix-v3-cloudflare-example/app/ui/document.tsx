import type { Handle, RemixNode } from 'remix/component'
import { Script } from 'vite-plugin-remix/client'

export interface DocumentProps {
  children?: RemixNode
  title?: string
  lang?: string
}

export const Document = (handle: Handle<DocumentProps>) => () => (
  <html lang={handle.props.lang ?? 'en'}>
    <head>
      <meta charSet='utf-8' />
      <meta name='viewport' content='width=device-width, initial-scale=1' />
      <title>{handle.props.title ?? 'Hono Remix Example'}</title>
    </head>
    <body>
      {handle.props.children}
      <Script devSrc='/app/assets/entry.ts' prodSrc='/assets/entry.js' />
    </body>
  </html>
)
