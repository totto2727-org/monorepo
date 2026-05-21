export const LoginPasskeyPage = () => () => (
  <div style={{ fontFamily: 'sans-serif', margin: '80px auto', maxWidth: '400px' }}>
    <h1>Passkey でログイン</h1>
    <button id='passkey-signin-btn' type='button'>
      Passkey でログイン
    </button>
    <p id='passkey-signin-error' role='alert' style={{ color: 'red', display: 'none', marginTop: 12 }} />
    <p style={{ marginTop: '24px' }}>
      <a href='/login'>Magic Link でログイン</a>
    </p>
    <script
      innerHTML={`
        function b64urlToBuf(s) {
          const pad = '='.repeat((4 - s.length % 4) % 4);
          const b = (s + pad).replace(/-/g, '+').replace(/_/g, '/');
          const raw = atob(b);
          const buf = new Uint8Array(raw.length);
          for (let i = 0; i < raw.length; i++) buf[i] = raw.charCodeAt(i);
          return buf.buffer;
        }
        function bufToB64url(buf) {
          const bytes = new Uint8Array(buf);
          let str = '';
          for (let i = 0; i < bytes.length; i++) str += String.fromCharCode(bytes[i]);
          return btoa(str).replace(/\\+/g, '-').replace(/\\//g, '_').replace(/=/g, '');
        }
        document.getElementById('passkey-signin-btn').addEventListener('click', async () => {
          const errorEl = document.getElementById('passkey-signin-error');
          errorEl.style.display = 'none';
          errorEl.textContent = '';
          try {
            const optsRes = await fetch('/api/v1/auth/passkey/generate-authenticate-options', {
              method: 'GET',
              credentials: 'include',
            });
            if (!optsRes.ok) {
              const text = await optsRes.text();
              throw new Error(text || 'Passkey 認証オプションの取得に失敗しました');
            }
            const opts = await optsRes.json();
            const publicKey = Object.assign({}, opts, {
              challenge: b64urlToBuf(opts.challenge),
              allowCredentials: (opts.allowCredentials || []).map((c) =>
                Object.assign({}, c, { id: b64urlToBuf(c.id) })
              ),
            });
            const credential = await navigator.credentials.get({ publicKey });
            if (!credential) throw new Error('Passkey 認証がキャンセルされました');
            const assertion = {
              id: credential.id,
              rawId: bufToB64url(credential.rawId),
              type: credential.type,
              authenticatorAttachment: credential.authenticatorAttachment,
              clientExtensionResults: credential.getClientExtensionResults(),
              response: {
                clientDataJSON: bufToB64url(credential.response.clientDataJSON),
                authenticatorData: bufToB64url(credential.response.authenticatorData),
                signature: bufToB64url(credential.response.signature),
                userHandle: credential.response.userHandle ? bufToB64url(credential.response.userHandle) : null,
              },
            };
            const verifyRes = await fetch('/api/v1/auth/passkey/verify-authentication', {
              method: 'POST',
              headers: { 'content-type': 'application/json' },
              credentials: 'include',
              body: JSON.stringify({ response: assertion }),
            });
            if (!verifyRes.ok) {
              const text = await verifyRes.text();
              throw new Error(text || 'Passkey 認証に失敗しました');
            }
            window.location.href = '/account';
          } catch (error) {
            errorEl.textContent = error instanceof Error ? error.message : 'Passkey 認証に失敗しました';
            errorEl.style.display = 'block';
          }
        });
      `}
    />
  </div>
)
