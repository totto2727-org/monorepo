import type { RemixNode } from 'remix/ui'
import { Script } from 'vite-plugin-remix/client'

export interface DocumentProps {
  children?: RemixNode
  title?: string
  lang?: string
}

export const Document = () => (props: DocumentProps) => (
  <html lang={props.lang ?? 'en'}>
    <head>
      <meta charSet='utf-8' />
      <meta name='viewport' content='width=device-width, initial-scale=1' />
      <title>{props.title ?? 'Identity Provider'}</title>
    </head>
    <body>
      {props.children}
      <Script devSrc='/app/assets/entry.ts' prodSrc='/assets/entry.js' />
    </body>
  </html>
)
