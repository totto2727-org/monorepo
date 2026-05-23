import { clientEntry, css, on } from 'remix/ui'
import type { Handle, SerializableProps } from 'remix/ui'

const containerStyle = css({
  fontFamily: 'sans-serif',
  margin: '80px auto',
  maxWidth: '400px',
})

const buttonStyle = css({
  '&:hover': {
    backgroundColor: '#1d4ed8',
  },
  backgroundColor: '#2563eb',
  border: 0,
  borderRadius: '8px',
  color: 'white',
  cursor: 'pointer',
  fontSize: '14px',
  fontWeight: 600,
  padding: '10px 24px',
})

const inputStyle = css({
  '&:focus-visible': {
    borderColor: '#2563eb',
    outline: 'none',
  },
  border: '1px solid #d1d5db',
  borderRadius: '8px',
  boxSizing: 'border-box',
  fontSize: '14px',
  marginTop: '4px',
  padding: '8px 12px',
  width: '100%',
})

const errStyle = css({
  color: 'red',
  marginTop: '12px',
})

const linkStyle = css({
  marginTop: '24px',
})

export const LoginPage = clientEntry(
  '/assets/app/ui/login.client.tsx#LoginPage',
  (handle: Handle<SerializableProps>) => {
    const errState = { message: '' }

    return () => (
      <div mix={containerStyle}>
        <h1>ログイン</h1>
        <form
          mix={on('submit', async (event, signal) => {
            event.preventDefault()
            errState.message = ''
            void handle.update()
            const form = event.currentTarget
            const email = new FormData(form).get('email') as string
            try {
              // oxlint-disable-next-line rules/no-fetch -- Remix client-side API call to own backend
              const response = await fetch('/api/v1/auth/sign-in/magic-link', {
                body: JSON.stringify({ callbackURL: '/auth/callback', email }),
                headers: { 'content-type': 'application/json' },
                method: 'POST',
                signal,
              })
              if (!response.ok) {
                const text = await response.text()
                throw new Error(text || 'マジックリンクの送信に失敗しました')
              }
              if (signal.aborted) {
                return
              }
              window.location.href = `/login/check-email?email=${encodeURIComponent(email)}`
            } catch (error) {
              if (signal.aborted) {
                return
              }
              errState.message = error instanceof Error ? error.message : 'マジックリンクの送信に失敗しました'
              void handle.update()
            }
          })}
        >
          <label>
            メールアドレス
            <input type='email' name='email' required mix={inputStyle} />
          </label>
          <div style={{ marginTop: '12px' }}>
            <button type='submit' mix={buttonStyle}>
              マジックリンクを送信
            </button>
          </div>
          {errState.message && (
            <p role='alert' mix={errStyle}>
              {errState.message}
            </p>
          )}
        </form>
        <p mix={linkStyle}>
          <a href='/login/passkey'>Passkey でログイン</a>
        </p>
      </div>
    )
  },
)
