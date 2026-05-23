import { clientEntry, css, on } from 'remix/ui'
import type { Handle, SerializableProps } from 'remix/ui'

interface AccountPageProps extends SerializableProps {
  createdAt: string
  email: string
}

const containerStyle = css({
  fontFamily: 'sans-serif',
  margin: '80px auto',
  maxWidth: '400px',
})

const logoutButtonStyle = css({
  '&:hover': {
    backgroundColor: '#dc2626',
  },
  backgroundColor: '#ef4444',
  border: 0,
  borderRadius: '8px',
  color: 'white',
  cursor: 'pointer',
  fontSize: '14px',
  fontWeight: 600,
  padding: '10px 24px',
})

const linkStyle = css({
  marginTop: '24px',
})

const errStyle = css({
  color: 'red',
  marginTop: '8px',
})

export const AccountPage = clientEntry(
  '/assets/app/ui/account.client.tsx#AccountPage',
  (handle: Handle<AccountPageProps>) => {
    const errState = { message: '' }

    return () => (
      <div mix={containerStyle}>
        <h1>アカウント</h1>
        <p>
          <strong>メール:</strong> {handle.props.email}
        </p>
        <p>
          <strong>作成日:</strong> {handle.props.createdAt}
        </p>
        <p mix={linkStyle}>
          <a href='/register/passkey'>Passkey を登録</a>
        </p>
        <button
          type='button'
          mix={[
            logoutButtonStyle,
            on('click', async (_, signal) => {
              errState.message = ''
              void handle.update()
              try {
                // oxlint-disable-next-line rules/no-fetch -- Remix client-side API call to own backend
                await fetch('/api/v1/auth/sign-out', {
                  credentials: 'include',
                  method: 'POST',
                  signal,
                })
                if (signal.aborted) {
                  return
                }
                window.location.href = '/login'
              } catch (error) {
                if (signal.aborted) {
                  return
                }
                errState.message = error instanceof Error ? error.message : 'ログアウトに失敗しました'
                void handle.update()
              }
            }),
          ]}
        >
          ログアウト
        </button>
        {errState.message && (
          <p role='alert' mix={errStyle}>
            {errState.message}
          </p>
        )}
      </div>
    )
  },
)
