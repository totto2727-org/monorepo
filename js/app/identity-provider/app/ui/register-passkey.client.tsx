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

export const RegisterPasskeyPage = clientEntry(
  '/assets/app/ui/register-passkey.client.tsx#RegisterPasskeyPage',
  (handle: Handle<SerializableProps>) => {
    const errState = { message: '' }

    return () => (
      <div mix={containerStyle}>
        <h1>Passkey を登録</h1>
        <p>このデバイスに Passkey を登録すると、次回からパスワードレスでログインできます。</p>
        <button
          type='button'
          mix={[
            buttonStyle,
            on('click', async (_, signal) => {
              errState.message = ''
              void handle.update()
              try {
                // oxlint-disable-next-line rules/no-fetch -- Remix client-side API call to own backend
                const optsRes = await fetch('/api/v1/auth/passkey/generate-register-options', {
                  credentials: 'include',
                  method: 'GET',
                  signal,
                })
                if (!optsRes.ok) {
                  const text = await optsRes.text()
                  throw new Error(text || 'Passkey 登録オプションの取得に失敗しました')
                }
                // oxlint-disable-next-line @typescript-eslint/no-unsafe-assignment -- WebAuthn server response shape
                const passthrough: Record<string, unknown> = await optsRes.json()
                const challenge = passthrough.challenge as string
                const userId = passthrough.user as { id: string }
                const excludeCredentials = (passthrough.excludeCredentials as { id: string }[] | undefined) ?? []
                const publicKey: PublicKeyCredentialCreationOptions = {
                  ...passthrough,
                  challenge: b64urlToBuf(challenge),
                  excludeCredentials: excludeCredentials.map((c) => ({
                    ...c,
                    id: b64urlToBuf(c.id),
                  })),
                  user: { ...userId, id: b64urlToBuf(userId.id) },
                } as PublicKeyCredentialCreationOptions
                const cred = await navigator.credentials.create({ publicKey })
                if (!cred) {
                  errState.message = 'Passkey の作成がキャンセルされました'
                  void handle.update()
                  return
                }
                const credential = cred as PublicKeyCredential
                const attestationResponse = credential.response as AuthenticatorAttestationResponse
                const regResponse = {
                  authenticatorAttachment: credential.authenticatorAttachment,
                  clientExtensionResults: credential.getClientExtensionResults(),
                  id: credential.id,
                  rawId: bufToB64url(credential.rawId),
                  response: {
                    attestationObject: bufToB64url(attestationResponse.attestationObject),
                    clientDataJSON: bufToB64url(attestationResponse.clientDataJSON),
                    transports: attestationResponse.getTransports ? attestationResponse.getTransports() : [],
                  },
                  type: credential.type,
                }
                // oxlint-disable-next-line rules/no-fetch -- Remix client-side API call to own backend
                const verifyRes = await fetch('/api/v1/auth/passkey/verify-registration', {
                  body: JSON.stringify({ response: regResponse }),
                  credentials: 'include',
                  headers: { 'content-type': 'application/json' },
                  method: 'POST',
                  signal,
                })
                if (!verifyRes.ok) {
                  const text = await verifyRes.text()
                  throw new Error(text || 'Passkey の検証に失敗しました')
                }
                if (signal.aborted) {
                  return
                }
                window.location.href = '/account'
              } catch (error) {
                if (signal.aborted) {
                  return
                }
                errState.message = error instanceof Error ? error.message : 'Passkey 登録に失敗しました'
                void handle.update()
              }
            }),
          ]}
        >
          Passkey を登録
        </button>
        {errState.message && (
          <p role='alert' mix={errStyle}>
            {errState.message}
          </p>
        )}
        <p mix={linkStyle}>
          <a href='/account'>スキップ</a>
        </p>
        <p>
          <a href='/login'>Magic Link でログイン</a>
        </p>
      </div>
    )
  },
)
