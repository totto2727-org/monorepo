import type { RemixNode } from 'remix/ui'
import { css } from 'remix/ui'

export interface LayoutProps {
  children?: RemixNode
}

const headerStyle = css({
  borderBottom: '1px solid #e5e7eb',
  padding: '12px 16px',
})

const navStyle = css({
  display: 'flex',
  gap: '16px',
  margin: '0 auto',
  maxWidth: '720px',
})

const linkStyle = css({
  '&:hover, &:focus-visible': {
    color: '#2563eb',
    outline: 'none',
  },
  color: '#111827',
  fontSize: '14px',
  fontWeight: 600,
  textDecoration: 'none',
})

const mainStyle = css({
  margin: '0 auto',
  maxWidth: '720px',
  padding: '24px 16px',
})

export const Layout =
  () =>
  ({ children }: LayoutProps) => (
    <>
      <header mix={headerStyle}>
        <nav mix={navStyle}>
          <a href='/' mix={linkStyle}>
            Counter
          </a>
          <a href='/todo' mix={linkStyle}>
            TODO
          </a>
        </nav>
      </header>
      <main mix={mainStyle}>{children}</main>
    </>
  )
