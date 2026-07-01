import { Effect, String } from 'effect'
import { FetchHttpClient, HttpBody, HttpClient, HttpClientRequest } from 'effect/unstable/http'
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
          mix={on('click', () => {
            // oxlint-disable-next-line rules/no-effect-runtime-run -- Client event boundary executes one sign-out workflow Effect.
            void Effect.runPromise(
              Effect.gen(function* () {
                state.error = ''
                state.submitting = true
                yield* Effect.promise(() => handle.update())

                const client = yield* HttpClient.HttpClient
                const response = yield* client.execute(
                  HttpClientRequest.post('/api/v1/auth/sign-out', { body: HttpBody.jsonUnsafe({}) }),
                )
                if (response.status !== 200) {
                  return yield* Effect.fail(new Error('ログアウトに失敗しました'))
                }

                window.location.href = '/login'
                return yield* Effect.void
              }).pipe(
                Effect.catch(() => {
                  state.error = 'ログアウトに失敗しました'
                  state.submitting = false
                  return Effect.promise(() => handle.update())
                }),
                Effect.provide(FetchHttpClient.layer),
              ),
            )
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
