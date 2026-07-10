import { Effect, Schema, String } from 'effect'
import { FetchHttpClient, HttpBody, HttpClient, HttpClientRequest } from 'effect/unstable/http'
import { clientEntry, on } from 'remix/ui'
import type { Handle, SerializableProps } from 'remix/ui'
import { Button } from 'remix/ui/button'

const ContinueResponse = Schema.Struct({
  redirect: Schema.Literal(true),
  url: Schema.String,
})

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- Better Auth continue response is an HTTP API boundary.
const decodeContinueResponse = Schema.decodeUnknownEffect(ContinueResponse)

export const SelectAccountButton = clientEntry(
  '/assets/app/ui/select-account.client.tsx#SelectAccountButton',
  (handle: Handle<SerializableProps>) => {
    const state = { error: '', submitting: false }

    return () => (
      <>
        <Button
          mix={on('click', () => {
            // oxlint-disable-next-line rules/no-effect-runtime-run -- Client event boundary executes one Better Auth OAuth continue workflow.
            void Effect.runPromise(
              Effect.gen(function* () {
                state.error = ''
                state.submitting = true
                yield* Effect.promise(() => handle.update())

                const { oauthQuery } = handle.props
                if (!String.isString(oauthQuery) || String.isEmpty(oauthQuery)) {
                  return yield* Effect.fail(new Error('OAuthリクエストが見つかりません'))
                }

                const client = yield* HttpClient.HttpClient
                const response = yield* client.execute(
                  HttpClientRequest.post('/api/v1/auth/oauth2/continue', {
                    body: HttpBody.jsonUnsafe({ oauth_query: oauthQuery, selected: true }),
                  }),
                )
                if (response.status < 200 || response.status >= 300) {
                  const text = yield* response.text
                  return yield* Effect.fail(
                    new Error(String.isNonEmpty(text) ? text : 'アカウント選択の続行に失敗しました'),
                  )
                }

                const result = yield* decodeContinueResponse(yield* response.json)
                window.location.href = result.url
                return yield* Effect.void
              }).pipe(
                Effect.catch(() => {
                  state.error = 'アカウント選択の続行に失敗しました'
                  state.submitting = false
                  return Effect.promise(() => handle.update())
                }),
                Effect.provide(FetchHttpClient.layer),
              ),
            )
          })}
          type='button'
          disabled={state.submitting}
        >
          {state.submitting ? '続行中...' : 'このアカウントで続行'}
        </Button>
        {String.isNonEmpty(state.error) ? <p role='alert'>{state.error}</p> : null}
      </>
    )
  },
)
