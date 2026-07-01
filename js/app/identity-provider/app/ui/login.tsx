import { css } from 'remix/ui'
import type { Handle } from 'remix/ui'

import { MagicLinkForm } from '#@/ui/login.client.tsx'

const containerStyle = css({
  margin: '40px auto',
  maxWidth: '400px',
  padding: '0 16px',
})

export const LoginPage = (_handle: Handle) => () => (
  <main mix={containerStyle}>
    <h1>ログイン</h1>
    <MagicLinkForm />
    <p>
      <a href='/login/passkey'>Passkey でログイン</a>
    </p>
  </main>
)
