import { Effect, Schema, String } from 'effect'
import { FetchHttpClient, HttpBody, HttpClient, HttpClientRequest } from 'effect/unstable/http'
import { clientEntry, css, on } from 'remix/ui'
import type { Handle, SerializableProps } from 'remix/ui'
import { Button } from 'remix/ui/button'

const formStyle = css({
  display: 'flex',
  gap: '12px',
})

const ConsentResponse = Schema.Struct({ redirect: Schema.Literal(true), url: Schema.NonEmptyString })

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- OAuth consent response JSON is an external API boundary.
const decodeConsentResponse = Schema.decodeUnknownEffect(ConsentResponse)

export const OAuthConsentForm = clientEntry(
  '/assets/app/ui/oauth-consent.client.tsx#OAuthConsentForm',
  (handle: Handle<SerializableProps>) => {
    const state = { error: '', submitting: false }

    const submitConsent = (accept: boolean) =>
      Effect.gen(function* () {
        state.error = ''
        state.submitting = true
        yield* Effect.promise(() => handle.update())

        const oauthQuery = window.location.search.slice(1)
        const client = yield* HttpClient.HttpClient
        const response = yield* client.execute(
          HttpClientRequest.post('/api/v1/auth/oauth2/consent', {
            body: HttpBody.jsonUnsafe({ accept, oauth_query: oauthQuery }),
          }),
        )
        if (response.status < 200 || response.status >= 300) {
          const text = yield* response.text
          return yield* Effect.fail(new Error(String.isNonEmpty(text) ? text : 'OAuth 認可に失敗しました'))
        }

        const result = yield* decodeConsentResponse(yield* response.json)
        window.location.href = result.url
        return yield* Effect.void
      }).pipe(
        Effect.catch(() => {
          state.error = 'OAuth 認可に失敗しました'
          state.submitting = false
          return Effect.promise(() => handle.update())
        }),
        Effect.provide(FetchHttpClient.layer),
      )

    return () => (
      <form method='POST' mix={formStyle}>
        <Button
          type='submit'
          name='action'
          value='allow'
          tone='primary'
          disabled={state.submitting}
          mix={on('click', (event) => {
            event.preventDefault()
            // oxlint-disable-next-line rules/no-effect-runtime-run -- Client event boundary executes one OAuth consent workflow Effect.
            void Effect.runPromise(submitConsent(true))
          })}
        >
          {state.submitting ? '処理中...' : '許可'}
        </Button>
        <Button
          type='submit'
          name='action'
          value='deny'
          tone='ghost'
          disabled={state.submitting}
          mix={on('click', (event) => {
            event.preventDefault()
            // oxlint-disable-next-line rules/no-effect-runtime-run -- Client event boundary executes one OAuth consent workflow Effect.
            void Effect.runPromise(submitConsent(false))
          })}
        >
          拒否
        </Button>
        {String.isNonEmpty(state.error) ? <p role='alert'>{state.error}</p> : null}
      </form>
    )
  },
)
