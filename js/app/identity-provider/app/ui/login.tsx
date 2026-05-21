export const LoginPage = () => () => (
  <div>
    <h1>ログイン</h1>
    <form id='magic-link-form'>
      <label>
        メールアドレス
        <input type='email' name='email' required />
      </label>
      <button type='submit'>マジックリンクを送信</button>
      <p id='magic-link-error' role='alert' style={{ color: 'red', display: 'none' }} />
    </form>
    <p>
      <a href='/login/passkey'>Passkey でログイン</a>
    </p>
    <script
      innerHTML={`
        document.getElementById('magic-link-form').addEventListener('submit', async (event) => {
          event.preventDefault();
          const form = event.currentTarget;
          const errorEl = document.getElementById('magic-link-error');
          errorEl.style.display = 'none';
          errorEl.textContent = '';
          const email = new FormData(form).get('email');
          try {
            const response = await fetch('/api/v1/auth/sign-in/magic-link', {
              method: 'POST',
              headers: { 'content-type': 'application/json' },
              body: JSON.stringify({ email, callbackURL: '/auth/callback' }),
            });
            if (!response.ok) {
              const text = await response.text();
              throw new Error(text || 'マジックリンクの送信に失敗しました');
            }
            window.location.href = '/login/check-email?email=' + encodeURIComponent(email);
          } catch (error) {
            errorEl.textContent = error instanceof Error ? error.message : 'マジックリンクの送信に失敗しました';
            errorEl.style.display = 'block';
          }
        });
      `}
    />
  </div>
)
