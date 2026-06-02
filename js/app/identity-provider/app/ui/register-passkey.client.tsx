import { Effect, Predicate, Schema, String } from 'effect'
import { FetchHttpClient, HttpBody, HttpClient, HttpClientRequest } from 'effect/unstable/http'
import { clientEntry, on } from 'remix/ui'
import type { Handle, SerializableProps } from 'remix/ui'
import { Button } from 'remix/ui/button'

import { withReturnTo } from '#@/ui/return-to.ts'
import { b64urlToBuf, bufToB64url } from '#@/ui/webauthn.ts'

const AuthenticatorSelection = Schema.Struct({
  authenticatorAttachment: Schema.optional(Schema.Literals(['cross-platform', 'platform'])),
  requireResidentKey: Schema.optional(Schema.Boolean),
  residentKey: Schema.optional(Schema.Literals(['discouraged', 'preferred', 'required'])),
  userVerification: Schema.optional(Schema.Literals(['discouraged', 'preferred', 'required'])),
})

const RegisterOptionsResponse = Schema.Struct({
  attestation: Schema.optional(Schema.Literals(['direct', 'enterprise', 'indirect', 'none'])),
  authenticatorSelection: Schema.optional(AuthenticatorSelection),
  challenge: Schema.String,
  excludeCredentials: Schema.optional(Schema.Array(Schema.Struct({ id: Schema.String }))),
  pubKeyCredParams: Schema.optional(Schema.Array(Schema.Struct({ alg: Schema.Number }))),
  rp: Schema.optional(Schema.Struct({ id: Schema.optional(Schema.String), name: Schema.optional(Schema.String) })),
  timeout: Schema.optional(Schema.Number),
  user: Schema.Struct({
    displayName: Schema.optional(Schema.String),
    id: Schema.String,
    name: Schema.optional(Schema.String),
  }),
})

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- WebAuthn options JSON is an external browser/API boundary.
const decodeRegisterOptionsResponse = Schema.decodeUnknownEffect(RegisterOptionsResponse)

interface PasskeyRegisterButtonProps extends SerializableProps {
  returnTo?: string
}

export const PasskeyRegisterButton = clientEntry(
  '/assets/app/ui/register-passkey.client.tsx#PasskeyRegisterButton',
  (handle: Handle<PasskeyRegisterButtonProps>) => {
    const state = { error: '', submitting: false }

    return () => (
      <>
        <Button
          mix={on('click', () => {
            // oxlint-disable-next-line rules/no-effect-runtime-run -- Client event boundary executes one Passkey registration workflow Effect.
            void Effect.runPromise(
              Effect.gen(function* () {
                state.error = ''
                state.submitting = true
                void handle.update()

                const client = yield* HttpClient.HttpClient
                const optsRes = yield* client.execute(
                  HttpClientRequest.get('/api/v1/auth/passkey/generate-register-options'),
                )
                if (optsRes.status < 200 || optsRes.status >= 300) {
                  const text = yield* optsRes.text
                  return yield* Effect.fail(
                    new Error(String.isNonEmpty(text) ? text : 'Passkey 登録オプションの取得に失敗しました'),
                  )
                }
                const opts = yield* decodeRegisterOptionsResponse(yield* optsRes.json)
                const publicKey: PublicKeyCredentialCreationOptions = {
                  attestation: opts.attestation,
                  authenticatorSelection: opts.authenticatorSelection,
                  challenge: b64urlToBuf(opts.challenge),
                  excludeCredentials: (opts.excludeCredentials ?? []).map((credential) => ({
                    id: b64urlToBuf(credential.id),
                    type: 'public-key',
                  })),
                  pubKeyCredParams: (opts.pubKeyCredParams ?? []).map((param) => ({
                    alg: param.alg,
                    type: 'public-key',
                  })),
                  rp: { id: opts.rp?.id, name: opts.rp?.name ?? 'Identity Provider' },
                  timeout: opts.timeout,
                  user: {
                    displayName: opts.user.displayName ?? opts.user.name ?? '',
                    id: b64urlToBuf(opts.user.id),
                    name: opts.user.name ?? '',
                  },
                }
                const credential = yield* Effect.promise(() => navigator.credentials.create({ publicKey }))
                if (Predicate.isNullish(credential)) {
                  return yield* Effect.fail(new Error('Passkey の作成がキャンセルされました'))
                }
                if (!(credential instanceof PublicKeyCredential)) {
                  return yield* Effect.fail(new Error('Passkey 登録レスポンスが不正です'))
                }
                const { response: attestationResponse } = credential
                if (!(attestationResponse instanceof AuthenticatorAttestationResponse)) {
                  return yield* Effect.fail(new Error('Passkey 登録レスポンスが不正です'))
                }
                const transports = Predicate.isFunction(attestationResponse.getTransports.bind(attestationResponse))
                  ? attestationResponse.getTransports()
                  : []
                const response = {
                  authenticatorAttachment: credential.authenticatorAttachment,
                  clientExtensionResults: credential.getClientExtensionResults(),
                  id: credential.id,
                  rawId: bufToB64url(credential.rawId),
                  response: {
                    attestationObject: bufToB64url(attestationResponse.attestationObject),
                    clientDataJSON: bufToB64url(attestationResponse.clientDataJSON),
                    transports,
                  },
                  type: credential.type,
                }
                const verifyRes = yield* client.execute(
                  HttpClientRequest.post('/api/v1/auth/passkey/verify-registration', {
                    body: HttpBody.jsonUnsafe({ response }),
                  }),
                )
                if (verifyRes.status < 200 || verifyRes.status >= 300) {
                  const text = yield* verifyRes.text
                  return yield* Effect.fail(new Error(String.isNonEmpty(text) ? text : 'Passkey の検証に失敗しました'))
                }

                window.location.href = withReturnTo('/app/auth/passkey/callback', handle.props.returnTo)
                return yield* Effect.void
              }).pipe(
                Effect.catch(() =>
                  Effect.sync(() => {
                    state.error = 'Passkey 登録に失敗しました'
                    state.submitting = false
                    void handle.update()
                  }),
                ),
                Effect.provide(FetchHttpClient.layer),
              ),
            )
          })}
          type='button'
          tone='primary'
          disabled={state.submitting}
        >
          {state.submitting ? '登録中...' : 'Passkey を登録'}
        </Button>
        {String.isNonEmpty(state.error) ? <p role='alert'>{state.error}</p> : null}
      </>
    )
  },
)
