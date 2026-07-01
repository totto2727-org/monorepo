import { css } from 'remix/ui'
import type { Handle } from 'remix/ui'

import { preserveReturnToLoginPath } from '#@/feature/auth/query-parameter.ts'
import { PasskeyRegisterButton } from '#@/ui/register-passkey.client.tsx'

const containerStyle = css({
  margin: '40px auto',
  maxWidth: '400px',
  padding: '0 16px',
})

export const RegisterPasskeyPage = (_handle: Handle) => () => (
  <main mix={containerStyle}>
    <h1>Passkey を登録</h1>
    <p>このデバイスに Passkey を登録すると、次回からパスワードレスでログインできます。</p>
    <PasskeyRegisterButton />
    <p>
      <a href='/app/account'>スキップ</a>
    </p>
    <p>
      <a href={preserveReturnToLoginPath}>Magic Link でログイン</a>
    </p>
  </main>
)
