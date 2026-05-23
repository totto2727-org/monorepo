import { clientEntry, css, on } from 'remix/ui'
import type { Handle, SerializableProps } from 'remix/ui'

function b64urlToBuf(s: string): ArrayBuffer {
  const pad = '='.repeat((4 - (s.length % 4)) % 4)
  const b = (s + pad).replaceAll('-', '+').replaceAll('_', '/')
  const raw = atob(b)
  return new Uint8Array([...raw].map((c) => c.codePointAt(0) ?? 0)).buffer
}

function bufToB64url(buf: ArrayBuffer): string {
  const bytes = new Uint8Array(buf)
  const str = [...bytes].map((b) => String.fromCodePoint(b)).join('')
  return btoa(str).replaceAll('+', '-').replaceAll('/', '_').replaceAll(/[=]/g, '')
}

const containerStyle = css({
  fontFamily: 'sans-serif',
  margin: '80px auto',
  maxWidth: '400px',
})

const buttonStyle = css({
  '&:hover': {
    backgroundColor: '#1d4ed8',
  },
  backgroundColor: '#2563eb',
  border: 0,
  borderRadius: '8px',
  color: 'white',
  cursor: 'pointer',
  fontSize: '14px',
  fontWeight: 600,
  padding: '10px 24px',
})

const errStyle = css({
  color: 'red',
  marginTop: '12px',
})

const linkStyle = css({
  marginTop: '24px',
})

export const LoginPasskeyPage = clientEntry(
  '/assets/app/ui/login-passkey.client.tsx#LoginPasskeyPage',
  (handle: Handle<SerializableProps>) => {
    const errState = { message: '' }

    return () => (
      <div mix={containerStyle}>
        <h1>Passkey でログイン</h1>
        <button
          type='button'
          mix={[
            buttonStyle,
            on('click', async (_, signal) => {
              errState.message = ''
              void handle.update()
              try {
                // oxlint-disable-next-line rules/no-fetch -- Remix client-side API call to own backend
                const optsRes = await fetch('/api/v1/auth/passkey/generate-authenticate-options', {
                  credentials: 'include',
                  method: 'GET',
                  signal,
                })
                if (!optsRes.ok) {
                  const text = await optsRes.text()
                  throw new Error(text || 'Passkey 認証オプションの取得に失敗しました')
                }
                // oxlint-disable-next-line @typescript-eslint/no-unsafe-assignment -- WebAuthn server response shape
                const passthrough: Record<string, unknown> = await optsRes.json()
                const challenge = passthrough.challenge as string
                const allowCredentials = (passthrough.allowCredentials as { id: string }[] | undefined) ?? []
                const publicKey: PublicKeyCredentialRequestOptions = {
                  ...passthrough,
                  allowCredentials: allowCredentials.map((c) => ({
                    ...c,
                    id: b64urlToBuf(c.id),
                  })),
                  challenge: b64urlToBuf(challenge),
                } as PublicKeyCredentialRequestOptions
                const cred = await navigator.credentials.get({ publicKey })
                if (!cred) {
                  errState.message = 'Passkey 認証がキャンセルされました'
                  void handle.update()
                  return
                }
                const credential = cred as PublicKeyCredential
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
                    userHandle: assertionResponse.userHandle ? bufToB64url(assertionResponse.userHandle) : null,
                  },
                  type: credential.type,
                }
                // oxlint-disable-next-line rules/no-fetch -- Remix client-side API call to own backend
                const verifyRes = await fetch('/api/v1/auth/passkey/verify-authentication', {
                  body: JSON.stringify({ response: assertion }),
                  credentials: 'include',
                  headers: { 'content-type': 'application/json' },
                  method: 'POST',
                  signal,
                })
                if (!verifyRes.ok) {
                  const text = await verifyRes.text()
                  throw new Error(text || 'Passkey 認証に失敗しました')
                }
                if (signal.aborted) {
                  return
                }
                window.location.href = '/account'
              } catch (error) {
                if (signal.aborted) {
                  return
                }
                errState.message = error instanceof Error ? error.message : 'Passkey ログインに失敗しました'
                void handle.update()
              }
            }),
          ]}
        >
          Passkey でログイン
        </button>
        {errState.message && (
          <p role='alert' mix={errStyle}>
            {errState.message}
          </p>
        )}
        <p mix={linkStyle}>
          <a href='/login'>Magic Link でログイン</a>
        </p>
      </div>
    )
  },
)
