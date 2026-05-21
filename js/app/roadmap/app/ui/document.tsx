import type { RemixNode } from 'remix/ui'
import { css } from 'remix/ui'

export interface DocumentProps {
  children?: RemixNode
  title?: string
}

const baseStyle = css({
  backgroundColor: '#f8fafc',
  color: '#0f172a',
  fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
  fontSize: '14px',
  lineHeight: '1.5',
  margin: '0',
  padding: '0',
})

const bodyStyle = css({
  margin: '0 auto',
  maxWidth: '1400px',
  padding: '24px 16px',
})

const headerStyle = css({
  '& h1': { fontSize: '24px', fontWeight: '700', marginBottom: '4px' },
  '& p': { color: '#64748b', fontSize: '14px' },
  borderBottom: '1px solid #e2e8f0',
  marginBottom: '24px',
  paddingBottom: '16px',
})

export const Document = () => (props: DocumentProps) => (
  <html lang='en' mix={baseStyle}>
    <head>
      <meta charset='utf-8' />
      <meta name='viewport' content='width=device-width, initial-scale=1' />
      <title>{props.title ?? 'Roadmap'}</title>
    </head>
    <body mix={bodyStyle}>
      <header mix={headerStyle}>
        <h1>{props.title ?? 'Roadmap'}</h1>
        <p>Kanban board — select roadmaps to display · updates in progress.yaml</p>
      </header>
      {props.children}
    </body>
  </html>
)
