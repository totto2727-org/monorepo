import { css } from 'remix/ui'
import type { Handle } from 'remix/ui'

import { PasskeyRegisterButton } from '#@/ui/register-passkey.client.tsx'
import { withReturnTo } from '#@/ui/return-to.ts'

const containerStyle = css({
  margin: '40px auto',
  maxWidth: '400px',
  padding: '0 16px',
})

interface RegisterPasskeyPageProps {
  returnTo?: string
}

export const RegisterPasskeyPage = (handle: Handle<RegisterPasskeyPageProps>) => () => (
  <main mix={containerStyle}>
    <h1>Passkey を登録</h1>
    <p>このデバイスに Passkey を登録すると、次回からパスワードレスでログインできます。</p>
    <PasskeyRegisterButton returnTo={handle.props.returnTo} />
    <p>
      <a href='/app/account'>スキップ</a>
    </p>
    <p>
      <a href={withReturnTo('/app/login', handle.props.returnTo)}>Magic Link でログイン</a>
    </p>
  </main>
)
