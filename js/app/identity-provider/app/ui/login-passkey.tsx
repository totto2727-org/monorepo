import { css } from 'remix/component'
import type { Handle } from 'remix/component'

import { preserveReturnToLoginPath } from '#@/feature/auth/query-parameter.ts'
import { PasskeyLoginButton } from '#@/ui/login-passkey.client.tsx'

const containerStyle = css({
  margin: '40px auto',
  maxWidth: '400px',
  padding: '0 16px',
})

export const LoginPasskeyPage = (_handle: Handle) => () => (
  <main mix={containerStyle}>
    <h1>Passkey でログイン</h1>
    <PasskeyLoginButton />
    <p>
      <a href={preserveReturnToLoginPath}>Magic Link でログイン</a>
    </p>
  </main>
)
