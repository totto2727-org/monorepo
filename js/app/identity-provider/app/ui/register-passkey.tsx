export const RegisterPasskeyPage = () => () => (
  <div style={{ fontFamily: 'sans-serif', margin: '80px auto', maxWidth: '400px' }}>
    <h1>Passkey を登録</h1>
    <p>このデバイスに Passkey を登録すると、次回からパスワードレスでログインできます。</p>
    <button id='register-passkey-btn' type='button'>
      Passkey を登録
    </button>
    <p id='register-passkey-error' role='alert' style='color:red;display:none;margin-top:12px' />
    <p style={{ marginTop: '24px' }}>
      <a href='/account'>スキップ</a>
    </p>
    <p>
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
        document.getElementById('register-passkey-btn').addEventListener('click', async () => {
          const errorEl = document.getElementById('register-passkey-error');
          errorEl.style.display = 'none';
          errorEl.textContent = '';
          try {
            const optsRes = await fetch('/api/v1/auth/passkey/generate-register-options', {
              method: 'GET',
              credentials: 'include',
            });
            if (!optsRes.ok) {
              const text = await optsRes.text();
              throw new Error(text || 'Passkey 登録オプションの取得に失敗しました');
            }
            const opts = await optsRes.json();
            const publicKey = Object.assign({}, opts, {
              challenge: b64urlToBuf(opts.challenge),
              user: Object.assign({}, opts.user, { id: b64urlToBuf(opts.user.id) }),
              excludeCredentials: (opts.excludeCredentials || []).map((c) =>
                Object.assign({}, c, { id: b64urlToBuf(c.id) })
              ),
            });
            const credential = await navigator.credentials.create({ publicKey });
            if (!credential) throw new Error('Passkey の作成がキャンセルされました');
            const response = {
              id: credential.id,
              rawId: bufToB64url(credential.rawId),
              type: credential.type,
              authenticatorAttachment: credential.authenticatorAttachment,
              clientExtensionResults: credential.getClientExtensionResults(),
              response: {
                clientDataJSON: bufToB64url(credential.response.clientDataJSON),
                attestationObject: bufToB64url(credential.response.attestationObject),
                transports: credential.response.getTransports ? credential.response.getTransports() : [],
              },
            };
            const verifyRes = await fetch('/api/v1/auth/passkey/verify-registration', {
              method: 'POST',
              headers: { 'content-type': 'application/json' },
              credentials: 'include',
              body: JSON.stringify({ response }),
            });
            if (!verifyRes.ok) {
              const text = await verifyRes.text();
              throw new Error(text || 'Passkey の検証に失敗しました');
            }
            window.location.href = '/account';
          } catch (error) {
            errorEl.textContent = error instanceof Error ? error.message : 'Passkey 登録に失敗しました';
            errorEl.style.display = 'block';
          }
        });
      `}
    />
  </div>
)
