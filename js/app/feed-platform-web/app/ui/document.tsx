import type { RemixNode } from 'remix/ui'
import { Script } from 'vite-plugin-remix/client'

export interface DocumentProps {
  children?: RemixNode
  title?: string
  lang?: string
}

// 最小 Document コンポーネント。SSR 出力の <html> 雛形と <Script> injection を担う。
// hono-remix-v3-cloudflare-example/app/ui/document.tsx と同形 (タイトルのみ差し替え)。
export const Document = () => (props: DocumentProps) => (
  <html lang={props.lang ?? 'en'}>
    <head>
      <meta charSet='utf-8' />
      <meta name='viewport' content='width=device-width, initial-scale=1' />
      <title>{props.title ?? 'feed-platform-web'}</title>
    </head>
    <body>
      {props.children}
      <Script devSrc='/app/assets/entry.ts' prodSrc='/assets/entry.js' />
    </body>
  </html>
)
