import { String } from 'effect'
import { clientEntry, on } from 'remix/ui'
import type { Handle, SerializableProps } from 'remix/ui'
import { Button } from 'remix/ui/button'

export const LogoutButton = clientEntry(
  '/assets/app/ui/account.client.tsx#LogoutButton',
  (handle: Handle<SerializableProps>) => {
    const state = { error: '', submitting: false }

    return () => (
      <>
        <Button
          mix={on('click', async () => {
            state.error = ''
            state.submitting = true
            void handle.update()
            try {
              // oxlint-disable-next-line rules/no-fetch -- IdP sign-out endpoint (browser context)
              await fetch('/api/v1/auth/sign-out', { credentials: 'include', method: 'POST' })
              window.location.href = '/app/login'
            } catch (error) {
              state.error = String(error) || 'ログアウトに失敗しました'
              state.submitting = false
              void handle.update()
            }
          })}
          type='button'
          tone='secondary'
          disabled={state.submitting}
        >
          {state.submitting ? 'ログアウト中...' : 'ログアウト'}
        </Button>
        {String.isNonEmpty(state.error) ? <p role='alert'>{state.error}</p> : null}
      </>
    )
  },
)
