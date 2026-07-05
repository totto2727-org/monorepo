import { css } from 'remix/ui'
import type { Handle } from 'remix/ui'

import { LogoutButton } from '#@/ui/account.client.tsx'

const containerStyle = css({
  margin: '40px auto',
  maxWidth: '400px',
  padding: '0 16px',
})

interface AccountPageProps {
  email: string
}

export const AccountPage = (handle: Handle<AccountPageProps>) => () => (
  <main mix={containerStyle}>
    <h1>アカウント</h1>
    <p>
      <strong>メール:</strong> {handle.props.email}
    </p>
    <p>
      <a href='/app/passkey/register'>Passkey を登録</a>
    </p>
    <LogoutButton />
  </main>
)
