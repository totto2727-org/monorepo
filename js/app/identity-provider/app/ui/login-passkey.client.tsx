/* oxlint-disable typescript-eslint/no-unsafe-type-assertion -- WebAuthn API returns CredentialResponse base types; narrowing is unavoidable at this boundary */
import { Predicate, String } from 'effect'
import { clientEntry, on } from 'remix/ui'
import type { Handle, SerializableProps } from 'remix/ui'
import { Button } from 'remix/ui/button'

import { withReturnTo } from '#@/ui/return-to.ts'
import { b64urlToBuf, bufToB64url } from '#@/ui/webauthn.ts'

interface AuthenticateOptionsResponse {
  challenge: string
  allowCredentials?: readonly { id: string; type?: string; transports?: readonly string[] }[]
  rpId?: string
  timeout?: number
  userVerification?: UserVerificationRequirement
  [key: string]: unknown
}

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
          mix={on('click', async () => {
            state.error = ''
            state.submitting = true
            void handle.update()
            try {
              // oxlint-disable-next-line rules/no-fetch -- IdP Passkey REST endpoint (browser context, no Effect runtime here)
              const optsRes = await fetch('/api/v1/auth/passkey/generate-authenticate-options', {
                credentials: 'include',
                method: 'GET',
              })
              if (!optsRes.ok) {
                const text = await optsRes.text()
                throw new Error(String.isNonEmpty(text) ? text : 'Passkey 認証オプションの取得に失敗しました')
              }
              const opts: AuthenticateOptionsResponse = await optsRes.json()
              const publicKey: PublicKeyCredentialRequestOptions = {
                ...opts,
                allowCredentials: (opts.allowCredentials ?? []).map((c) => ({
                  id: b64urlToBuf(c.id),
                  transports: c.transports as AuthenticatorTransport[] | undefined,
                  type: 'public-key',
                })),
                challenge: b64urlToBuf(opts.challenge),
              }
              const credential = (await navigator.credentials.get({ publicKey })) as PublicKeyCredential | null
              if (Predicate.isNullish(credential)) {
                throw new Error('Passkey 認証がキャンセルされました')
              }
              const assertionResponse = credential.response as AuthenticatorAssertionResponse
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
              // oxlint-disable-next-line rules/no-fetch -- IdP Passkey verification endpoint
              const verifyRes = await fetch('/api/v1/auth/passkey/verify-authentication', {
                body: JSON.stringify({ response: assertion }),
                credentials: 'include',
                headers: { 'content-type': 'application/json' },
                method: 'POST',
              })
              if (!verifyRes.ok) {
                const text = await verifyRes.text()
                throw new Error(String.isNonEmpty(text) ? text : 'Passkey 認証に失敗しました')
              }
              window.location.href = withReturnTo('/app/auth/passkey/callback', handle.props.returnTo)
            } catch (error) {
              state.error = error instanceof Error ? error.message : 'Passkey 認証に失敗しました'
              state.submitting = false
              void handle.update()
            }
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
