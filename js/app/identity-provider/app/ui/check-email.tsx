import { css } from 'remix/ui'
import type { Handle } from 'remix/ui'

import { preserveReturnToLoginPath } from '#@/feature/auth/query-parameter.ts'

const containerStyle = css({
  margin: '40px auto',
  maxWidth: '400px',
  padding: '0 16px',
})

interface CheckEmailPageProps {
  email: string
}

export const CheckEmailPage = (handle: Handle<CheckEmailPageProps>) => () => (
  <main mix={containerStyle}>
    <h1>メールを確認してください</h1>
    <p>
      <strong>{handle.props.email}</strong> 宛に Magic Link を送信しました。
    </p>
    <p>メールをチェックしてリンクをクリックしてください。</p>
    <p>
      <a href={preserveReturnToLoginPath}>ログイン画面に戻る</a>
    </p>
  </main>
)
