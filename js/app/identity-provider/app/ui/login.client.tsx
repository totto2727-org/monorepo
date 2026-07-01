import { Effect, Predicate, String } from 'effect'
import { FetchHttpClient, HttpBody, HttpClient, HttpClientRequest } from 'effect/unstable/http'
import { clientEntry, css, on } from 'remix/ui'
import type { Handle } from 'remix/ui'
import { Button } from 'remix/ui/button'

const formStyle = css({
  display: 'flex',
  flexDirection: 'column',
  gap: '12px',
})

export const MagicLinkForm = clientEntry('/assets/app/ui/login.client.tsx#MagicLinkForm', (handle: Handle) => {
  const state = { error: '', submitting: false }

  return () => (
    <form
      mix={[
        formStyle,
        on('submit', (event) => {
          // oxlint-disable-next-line rules/no-effect-runtime-run -- Client event boundary executes one magic-link workflow Effect.
          void Effect.runPromise(
            Effect.gen(function* () {
              event.preventDefault()
              const form = event.currentTarget
              const formData = new FormData(form)
              const email = formData.get('email')

              if (!Predicate.isString(email) || String.isEmpty(email)) {
                state.error = 'メールアドレスを入力してください'
                return yield* Effect.promise(() => handle.update())
              }

              state.error = ''
              state.submitting = true
              yield* Effect.promise(() => handle.update())

              const params = new URLSearchParams({ email })

              const client = yield* HttpClient.HttpClient
              const request = HttpClientRequest.post('/api/v1/auth/sign-in/magic-link', {
                body: HttpBody.jsonUnsafe({ callbackURL: '/login/callback', email }),
              })
              const response = yield* client.execute(request)
              if (response.status < 200 || response.status >= 300) {
                const text = yield* response.text
                return yield* Effect.fail(
                  new Error(String.isNonEmpty(text) ? text : 'マジックリンクの送信に失敗しました'),
                )
              }

              window.location.href = `/login/check-email?${params.toString()}`
              return yield* Effect.void
            }).pipe(
              Effect.catch(() => {
                state.error = 'マジックリンクの送信に失敗しました'
                state.submitting = false
                return Effect.promise(() => handle.update())
              }),
              Effect.provide(FetchHttpClient.layer),
            ),
          )
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
})
