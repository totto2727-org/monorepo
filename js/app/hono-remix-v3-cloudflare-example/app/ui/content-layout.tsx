import { getContext } from 'hono/context-storage'
import type { Handle, RemixNode } from 'remix/ui'
import { Frame, css } from 'remix/ui'

import { frames } from '../routes.ts'
import { Counter } from './counter.client.tsx'
import { Document } from './document.tsx'
import { FrameLink } from './frame-link.tsx'
import { createPageOrFrame } from './page-or-frame.tsx'

interface LayoutProps {
  title: string
  children?: RemixNode
}

const headerStyle = css({
  borderBottom: '1px solid #e5e7eb',
  padding: '12px 16px',
})

const navStyle = css({
  '& a': {
    color: '#111827',
    fontSize: '14px',
    fontWeight: 600,
    textDecoration: 'none',
  },
  '& a:hover, & a:focus-visible': {
    color: '#2563eb',
    outline: 'none',
  },
  display: 'flex',
  gap: '16px',
  margin: '0 auto',
  maxWidth: '720px',
})

const mainStyle = css({
  margin: '0 auto',
  maxWidth: '720px',
  padding: '24px 16px',
})

const Layout = (handle: Handle<LayoutProps>) => () => (
  <Document title={handle.props.title}>
    <header mix={headerStyle}>
      <nav mix={navStyle}>
        <FrameLink href='/' rmx-target={frames.content} rmx-src='/'>
          Counter
        </FrameLink>
        <FrameLink href='/todo' rmx-target={frames.content} rmx-src='/todo'>
          TODO
        </FrameLink>
      </nav>
    </header>
    <main mix={mainStyle}>
      <Counter initial={0} />
      <Frame name={frames.content} src={getContext().req.url} />
    </main>
  </Document>
)

export const PageOrFrame = createPageOrFrame(frames.content, Layout)
