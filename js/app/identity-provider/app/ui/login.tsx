import { css } from 'remix/ui'
import type { Handle } from 'remix/ui'

import { MagicLinkForm } from '#@/ui/login.client.tsx'
import { withReturnTo } from '#@/ui/return-to.ts'

const containerStyle = css({
  margin: '40px auto',
  maxWidth: '400px',
  padding: '0 16px',
})

interface LoginPageProps {
  returnTo?: string
}

export const LoginPage = (handle: Handle<LoginPageProps>) => () => (
  <main mix={containerStyle}>
    <h1>ログイン</h1>
    <MagicLinkForm returnTo={handle.props.returnTo} />
    <p>
      <a href={withReturnTo('/app/login/passkey', handle.props.returnTo)}>Passkey でログイン</a>
    </p>
  </main>
)
