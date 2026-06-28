import { Effect, Predicate, Schema, String } from 'effect'
import { FetchHttpClient, HttpBody, HttpClient, HttpClientRequest } from 'effect/unstable/http'
import { clientEntry, on } from 'remix/ui'
import type { Handle, SerializableProps } from 'remix/ui'
import { Button } from 'remix/ui/button'

import { withReturnTo } from '#@/ui/return-to.ts'
import { b64urlToBuf, bufToB64url } from '#@/ui/webauthn.ts'

const AuthenticateOptionsResponse = Schema.Struct({
  allowCredentials: Schema.optional(Schema.Array(Schema.Struct({ id: Schema.String }))),
  challenge: Schema.String,
  rpId: Schema.optional(Schema.String),
  timeout: Schema.optional(Schema.Number),
  userVerification: Schema.optional(Schema.Literals(['discouraged', 'preferred', 'required'])),
})

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- WebAuthn options JSON is an external browser/API boundary.
const decodeAuthenticateOptionsResponse = Schema.decodeUnknownEffect(AuthenticateOptionsResponse)

interface PasskeyLoginButtonProps extends SerializableProps {
  returnTo?: string
}

export const PasskeyLoginButton = clientEntry(
  '/assets/app/ui/login-passkey.client.tsx#PasskeyLoginButton',
  (handle: Handle<PasskeyLoginButtonProps>) => {
    const state = { error: '', submitting: false }

    return () => (
      <>
        <Button
          mix={on('click', () => {
            // oxlint-disable-next-line rules/no-effect-runtime-run -- Client event boundary executes one Passkey authentication workflow Effect.
            void Effect.runPromise(
              Effect.gen(function* () {
                state.error = ''
                state.submitting = true
                yield* Effect.promise(() => handle.update())

                const client = yield* HttpClient.HttpClient
                const optsRes = yield* client.execute(
                  HttpClientRequest.get('/api/v1/auth/passkey/generate-authenticate-options'),
                )
                if (optsRes.status < 200 || optsRes.status >= 300) {
                  const text = yield* optsRes.text
                  return yield* Effect.fail(
                    new Error(String.isNonEmpty(text) ? text : 'Passkey 認証オプションの取得に失敗しました'),
                  )
                }
                const opts = yield* decodeAuthenticateOptionsResponse(yield* optsRes.json)
                const publicKey: PublicKeyCredentialRequestOptions = {
                  ...opts,
                  allowCredentials: (opts.allowCredentials ?? []).map((credential) => ({
                    id: b64urlToBuf(credential.id),
                    type: 'public-key',
                  })),
                  challenge: b64urlToBuf(opts.challenge),
                }
                const credential = yield* Effect.promise(() => navigator.credentials.get({ publicKey }))
                if (Predicate.isNullish(credential)) {
                  return yield* Effect.fail(new Error('Passkey 認証がキャンセルされました'))
                }
                if (!(credential instanceof PublicKeyCredential)) {
                  return yield* Effect.fail(new Error('Passkey 認証レスポンスが不正です'))
                }
                const { response: assertionResponse } = credential
                if (!(assertionResponse instanceof AuthenticatorAssertionResponse)) {
                  return yield* Effect.fail(new Error('Passkey 認証レスポンスが不正です'))
                }
                const assertion = {
                  authenticatorAttachment: credential.authenticatorAttachment,
                  clientExtensionResults: credential.getClientExtensionResults(),
                  id: credential.id,
                  rawId: bufToB64url(credential.rawId),
                  response: {
                    authenticatorData: bufToB64url(assertionResponse.authenticatorData),
                    clientDataJSON: bufToB64url(assertionResponse.clientDataJSON),
                    signature: bufToB64url(assertionResponse.signature),
                    userHandle: Predicate.isNotNullish(assertionResponse.userHandle)
                      ? bufToB64url(assertionResponse.userHandle)
                      : null,
                  },
                  type: credential.type,
                }
                const verifyRes = yield* client.execute(
                  HttpClientRequest.post('/api/v1/auth/passkey/verify-authentication', {
                    body: HttpBody.jsonUnsafe({ response: assertion }),
                  }),
                )
                if (verifyRes.status < 200 || verifyRes.status >= 300) {
                  const text = yield* verifyRes.text
                  return yield* Effect.fail(new Error(String.isNonEmpty(text) ? text : 'Passkey 認証に失敗しました'))
                }

                window.location.href = withReturnTo('/app/auth/passkey/callback', handle.props.returnTo)
                return yield* Effect.void
              }).pipe(
                Effect.catch(() => {
                  state.error = 'Passkey 認証に失敗しました'
                  state.submitting = false
                  return Effect.promise(() => handle.update())
                }),
                Effect.provide(FetchHttpClient.layer),
              ),
            )
          })}
          type='button'
          tone='primary'
          disabled={state.submitting}
        >
          {state.submitting ? '認証中...' : 'Passkey でログイン'}
        </Button>
        {String.isNonEmpty(state.error) ? <p role='alert'>{state.error}</p> : null}
      </>
    )
  },
)
