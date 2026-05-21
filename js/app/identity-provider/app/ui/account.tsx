interface AccountPageProps {
  email: string
  createdAt: string
}

export const AccountPage =
  ({ email, createdAt }: AccountPageProps) =>
  () =>
  () => (
    <div style={{ fontFamily: 'sans-serif', margin: '80px auto', maxWidth: '400px' }}>
      <h1>アカウント</h1>
      <p>
        <strong>メール:</strong> {email}
      </p>
      <p>
        <strong>作成日:</strong> {createdAt}
      </p>
      <p>
        <a href='/register/passkey'>Passkey を登録</a>
      </p>
      <button id='logout-btn' type='button'>
        ログアウト
      </button>
      <p id='logout-error' role='alert' style='color:red;display:none;margin-top:8px' />
      <script
        innerHTML={`
        document.getElementById('logout-btn').addEventListener('click', async () => {
          const errorEl = document.getElementById('logout-error');
          errorEl.style.display = 'none';
          try {
            await fetch('/api/v1/auth/sign-out', { method: 'POST', credentials: 'include' });
            window.location.href = '/login';
          } catch (error) {
            errorEl.textContent = error instanceof Error ? error.message : 'ログアウトに失敗しました';
            errorEl.style.display = 'block';
          }
        });
      `}
      />
    </div>
  )
