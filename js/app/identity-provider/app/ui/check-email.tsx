import { css } from 'remix/ui'
import type { Handle } from 'remix/ui'

import { withReturnTo } from '#@/ui/return-to.ts'

const containerStyle = css({
  margin: '40px auto',
  maxWidth: '400px',
  padding: '0 16px',
})

interface CheckEmailPageProps {
  email: string
  returnTo?: string
}

export const CheckEmailPage = (handle: Handle<CheckEmailPageProps>) => () => (
  <main mix={containerStyle}>
    <h1>メールを確認してください</h1>
    <p>
      <strong>{handle.props.email}</strong> 宛に Magic Link を送信しました。
    </p>
    <p>メールをチェックしてリンクをクリックしてください。</p>
    <p>
      <a href={withReturnTo('/app/login', handle.props.returnTo)}>ログイン画面に戻る</a>
    </p>
  </main>
)
