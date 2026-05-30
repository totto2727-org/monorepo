import { Predicate, String } from 'effect'
import { clientEntry, on } from 'remix/ui'
import type { Handle, SerializableProps } from 'remix/ui'
import { Button } from 'remix/ui/button'

import { withReturnTo } from '#@/ui/return-to.ts'
import { b64urlToBuf, bufToB64url } from '#@/ui/webauthn.ts'

interface RegisterOptionsResponse {
  challenge: string
  user: { id: string; name?: string; displayName?: string }
  rp?: { id?: string; name?: string }
  pubKeyCredParams?: readonly PublicKeyCredentialParameters[]
  excludeCredentials?: readonly { id: string; type?: string; transports?: readonly string[] }[]
  timeout?: number
  attestation?: AttestationConveyancePreference
  authenticatorSelection?: AuthenticatorSelectionCriteria
  [key: string]: unknown
}

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
          mix={on('click', async () => {
            state.error = ''
            state.submitting = true
            void handle.update()
            try {
              // oxlint-disable-next-line rules/no-fetch -- IdP Passkey REST endpoint
              const optsRes = await fetch('/api/v1/auth/passkey/generate-register-options', {
                credentials: 'include',
                method: 'GET',
              })
              if (!optsRes.ok) {
                const text = await optsRes.text()
                throw new Error(String.isNonEmpty(text) ? text : 'Passkey 登録オプションの取得に失敗しました')
              }
              const opts: RegisterOptionsResponse = await optsRes.json()
              const publicKey: PublicKeyCredentialCreationOptions = {
                attestation: opts.attestation,
                authenticatorSelection: opts.authenticatorSelection,
                challenge: b64urlToBuf(opts.challenge),
                excludeCredentials: (opts.excludeCredentials ?? []).map((c) => ({
                  id: b64urlToBuf(c.id),
                  transports: c.transports as AuthenticatorTransport[] | undefined,
                  type: 'public-key',
                })),
                pubKeyCredParams: Predicate.isNotNullish(opts.pubKeyCredParams) ? [...opts.pubKeyCredParams] : [],
                rp: { id: opts.rp?.id, name: opts.rp?.name ?? 'Identity Provider' },
                timeout: opts.timeout,
                user: {
                  displayName: opts.user.displayName ?? opts.user.name ?? '',
                  id: b64urlToBuf(opts.user.id),
                  name: opts.user.name ?? '',
                },
              }
              const credential = (await navigator.credentials.create({ publicKey })) as PublicKeyCredential | null
              if (Predicate.isNullish(credential)) {
                throw new Error('Passkey の作成がキャンセルされました')
              }
              const attestationResponse = credential.response as AuthenticatorAttestationResponse
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
              // oxlint-disable-next-line rules/no-fetch -- IdP Passkey verification endpoint
              const verifyRes = await fetch('/api/v1/auth/passkey/verify-registration', {
                body: JSON.stringify({ response }),
                credentials: 'include',
                headers: { 'content-type': 'application/json' },
                method: 'POST',
              })
              if (!verifyRes.ok) {
                const text = await verifyRes.text()
                throw new Error(String.isNonEmpty(text) ? text : 'Passkey の検証に失敗しました')
              }
              window.location.href = withReturnTo('/app/auth/passkey/callback', handle.props.returnTo)
            } catch (error) {
              state.error = String(error) || 'Passkey 登録に失敗しました'
              state.submitting = false
              void handle.update()
            }
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
