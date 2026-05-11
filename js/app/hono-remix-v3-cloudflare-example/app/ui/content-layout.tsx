import { getContext } from 'hono/context-storage'
import { createFrameHelpers } from 'remix-helper'
import type { Handle, RemixNode } from 'remix/ui'
import { Frame, css } from 'remix/ui'

import type { FrameName } from '../routes.ts'
import { Counter } from './counter.client.tsx'
import { Document } from './document.tsx'

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

const helpers = createFrameHelpers<FrameName>()

const Layout = (handle: Handle<LayoutProps>) => () => (
  <Document title={handle.props.title}>
    <header mix={headerStyle}>
      <nav mix={navStyle}>
        <helpers.FrameLink href='/' rmx-target={'content'} rmx-src='/'>
          Counter
        </helpers.FrameLink>
        <helpers.FrameLink href='/todo' rmx-target={'content'} rmx-src='/todo'>
          TODO
        </helpers.FrameLink>
      </nav>
    </header>
    <main mix={mainStyle}>
      <Counter initial={0} />
      <Frame name={'content'} src={getContext().req.url} />
    </main>
  </Document>
)

const pageOrFrame = helpers.createPageOrFrame('content', Layout)

export const PageOrFrame = (handle: Handle<LayoutProps>) => pageOrFrame(getContext().req.raw)(handle)
