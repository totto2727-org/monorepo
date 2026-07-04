import { css } from 'remix/ui'
import type { Handle } from 'remix/ui'

import { SelectAccountButton } from '#@/ui/select-account.client.tsx'

const containerStyle = css({
  margin: '40px auto',
  maxWidth: '400px',
  padding: '0 16px',
})

interface SelectAccountPageProps {
  email: string
  oauthQuery: string
}

export const SelectAccountPage = (handle: Handle<SelectAccountPageProps>) => () => (
  <main mix={containerStyle}>
    <h1>アカウントの選択</h1>
    <p>
      <strong>メール:</strong> {handle.props.email}
    </p>
    <SelectAccountButton oauthQuery={handle.props.oauthQuery} />
  </main>
)
