import { Effect, String } from 'effect'
import { FetchHttpClient, HttpClient, HttpClientRequest } from 'effect/unstable/http'
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
              // oxlint-disable-next-line rules/no-effect-runtime-run -- Client event boundary executes one sign-out workflow Effect.
              await Effect.runPromise(
                Effect.gen(function* () {
                  const client = yield* HttpClient.HttpClient
                  const response = yield* client.execute(HttpClientRequest.post('/api/v1/auth/sign-out'))
                  if (response.status !== 200) {
                    return yield* Effect.fail(new Error('ログアウトに失敗しました'))
                  }
                  return true
                }).pipe(Effect.provide(FetchHttpClient.layer)),
              )
              window.location.href = '/app/login'
            } catch {
              state.error = 'ログアウトに失敗しました'
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
