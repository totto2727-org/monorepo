import { css } from 'remix/ui'
import type { Handle } from 'remix/ui'

import { PasskeyLoginButton } from '#@/ui/login-passkey.client.tsx'
import { withReturnTo } from '#@/ui/return-to.ts'

const containerStyle = css({
  margin: '40px auto',
  maxWidth: '400px',
  padding: '0 16px',
})

interface LoginPasskeyPageProps {
  returnTo?: string
}

export const LoginPasskeyPage = (handle: Handle<LoginPasskeyPageProps>) => () => (
  <main mix={containerStyle}>
    <h1>Passkey でログイン</h1>
    <PasskeyLoginButton returnTo={handle.props.returnTo} />
    <p>
      <a href={withReturnTo('/app/login', handle.props.returnTo)}>Magic Link でログイン</a>
    </p>
  </main>
)
