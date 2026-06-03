import { css } from 'remix/ui'
import type { Handle } from 'remix/ui'

import { OAuthConsentForm } from '#@/ui/oauth-consent.client.tsx'

const containerStyle = css({
  margin: '40px auto',
  maxWidth: '480px',
  padding: '0 16px',
})

interface ConsentPageProps {
  clientId: string
  scope: string
  redirectUri: string
  state: string
}

export const OAuthConsentPage = (handle: Handle<ConsentPageProps>) => () => (
  <main mix={containerStyle}>
    <h1>アプリケーション連携の承認</h1>
    <p>
      アプリケーション <strong>{handle.props.clientId}</strong> が以下の権限をリクエストしています：
    </p>
    <ul>
      {handle.props.scope.split(' ').map((s) => (
        <li key={s}>{s}</li>
      ))}
    </ul>
    <p>リダイレクト先: {handle.props.redirectUri}</p>
    <OAuthConsentForm />
  </main>
)

interface ErrorPageProps {
  message: string
}

export const OAuthConsentErrorPage = (handle: Handle<ErrorPageProps>) => () => (
  <main mix={containerStyle}>
    <h1>パラメータエラー</h1>
    <p>{handle.props.message}</p>
  </main>
)
