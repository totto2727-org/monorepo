import type { RemixNode } from 'remix/ui'
import { Script } from 'vite-plugin-remix/client'

export interface DocumentProps {
  children?: RemixNode
  title?: string
}

const DEFAULT_TITLE = decodeURIComponent('My%20Remix%20App2')

export function Document() {
  return ({ title = DEFAULT_TITLE, children }: DocumentProps) => (
    <html lang='en'>
      <head>
        <meta charSet='utf-8' />
        <meta name='viewport' content='width=device-width, initial-scale=1' />
        <title>{title}</title>
      </head>
      <body>
        {children}
        <Script devSrc='/app/assets/entry.ts' prodSrc='/assets/entry.js' />
      </body>
    </html>
  )
}
