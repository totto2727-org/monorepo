export const CheckEmailPage = (email: string) => () => () => (
  <div style={{ fontFamily: 'sans-serif', margin: '80px auto', maxWidth: '400px' }}>
    <h1>メールを確認してください</h1>
    <p>
      <strong>{email}</strong> 宛に Magic Link を送信しました。
    </p>
    <p>メールをチェックしてリンクをクリックしてください。</p>
    <p>
      <a href='/login'>ログイン画面に戻る</a>
    </p>
  </div>
)
