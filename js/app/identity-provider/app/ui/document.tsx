import { css } from 'remix/component'
import type { Handle, RemixNode } from 'remix/component'
import { Script } from 'vite-plugin-remix/client'

export interface DocumentProps {
  children?: RemixNode
  title?: string
  lang?: string
}

const documentStyle = css({
  '& button': {
    border: '1px solid #d8d8d8',
    borderRadius: '999px',
    cursor: 'pointer',
    font: 'inherit',
    padding: '8px 16px',
  },
  '& button:disabled': { cursor: 'default', opacity: 0.5 },
  '& button:focus-visible': { outline: '2px solid #1d4ed8', outlineOffset: '2px' },
  '& button[data-tone="primary"]': { background: '#1d4ed8', color: '#fff' },
  background: '#fff',
  color: '#111',
  fontFamily: 'system-ui, sans-serif',
})

export const Document = (handle: Handle<DocumentProps>) => () => (
  <html lang={handle.props.lang ?? 'ja'}>
    <head>
      <meta charSet='utf-8' />
      <meta name='viewport' content='width=device-width, initial-scale=1' />
      <title>{handle.props.title ?? 'Identity Provider'}</title>
    </head>
    <body mix={documentStyle}>
      {handle.props.children}
      <Script devSrc='/app/assets/entry.ts' prodSrc='/assets/entry.js' />
    </body>
  </html>
)
