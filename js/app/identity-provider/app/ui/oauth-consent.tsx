import { css } from 'remix/ui'
import type { Handle } from 'remix/ui'
import { Button } from 'remix/ui/button'

const containerStyle = css({
  margin: '40px auto',
  maxWidth: '480px',
  padding: '0 16px',
})

const formStyle = css({
  display: 'flex',
  gap: '12px',
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
    <form action='/api/v1/auth/oauth2/confirm-consent' method='POST' mix={formStyle}>
      <input type='hidden' name='clientId' value={handle.props.clientId} />
      <input type='hidden' name='redirectUri' value={handle.props.redirectUri} />
      <input type='hidden' name='state' value={handle.props.state} />
      <Button type='submit' name='action' value='allow' tone='primary'>
        許可
      </Button>
      <Button type='submit' name='action' value='deny' tone='ghost'>
        拒否
      </Button>
    </form>
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
