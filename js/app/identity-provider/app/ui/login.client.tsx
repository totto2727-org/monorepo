import { Predicate, String } from 'effect'
import { clientEntry, css, on } from 'remix/ui'
import type { Handle, SerializableProps } from 'remix/ui'
import { Button } from 'remix/ui/button'

import { withReturnTo } from '#@/ui/return-to.ts'

const formStyle = css({
  display: 'flex',
  flexDirection: 'column',
  gap: '12px',
})

interface MagicLinkFormProps extends SerializableProps {
  returnTo?: string
}

export const MagicLinkForm = clientEntry(
  '/assets/app/ui/login.client.tsx#MagicLinkForm',
  (handle: Handle<MagicLinkFormProps>) => {
    const state = { error: '', submitting: false }

    return () => (
      <form
        mix={[
          formStyle,
          on('submit', async (event) => {
            event.preventDefault()
            const form = event.currentTarget
            const formData = new FormData(form)
            const email = formData.get('email')
            if (!Predicate.isString(email) || String.isEmpty(email)) {
              state.error = 'メールアドレスを入力してください'
              void handle.update()
              return
            }
            state.error = ''
            state.submitting = true
            void handle.update()
            try {
              const callbackURL = withReturnTo('/app/auth/magic-link/callback', handle.props.returnTo)
              // oxlint-disable-next-line rules/no-fetch -- IdP Magic Link endpoint (browser context)
              const response = await fetch('/api/v1/auth/sign-in/magic-link', {
                body: JSON.stringify({ callbackURL, email }),
                headers: { 'content-type': 'application/json' },
                method: 'POST',
              })
              if (!response.ok) {
                const text = await response.text()
                throw new Error(String.isNonEmpty(text) ? text : 'マジックリンクの送信に失敗しました')
              }
              const params = new URLSearchParams({ email })
              if (Predicate.isNotNullish(handle.props.returnTo)) {
                params.set('return_to', handle.props.returnTo)
              }
              window.location.href = `/app/login/check-email?${params.toString()}`
            } catch (error) {
              state.error = String(error) || 'マジックリンクの送信に失敗しました'
              state.submitting = false
              void handle.update()
            }
          }),
        ]}
      >
        <label htmlFor='login-email'>メールアドレス</label>
        <input
          id='login-email'
          type='email'
          name='email'
          aria-label='メールアドレス'
          required
          disabled={state.submitting}
        />
        <Button type='submit' tone='primary' disabled={state.submitting}>
          {state.submitting ? '送信中...' : 'マジックリンクを送信'}
        </Button>
        {String.isNonEmpty(state.error) ? <p role='alert'>{state.error}</p> : null}
      </form>
    )
  },
)
