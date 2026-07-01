# Feed Platform & IdP 連携検証レポート

## 検証概要

| 項目                      | 値                    |
| ------------------------- | --------------------- |
| 検証日時                  | 2026-07-01            |
| 検証環境                  | ローカル開発環境      |
| IdP URL                   | http://localhost:8787 |
| Feed Platform Web URL     | http://127.0.0.1:8789 |
| Feed Platform Backend URL | http://127.0.0.1:8788 |

## 検証結果

**総合評価: ✅ 正常に動作**

IdPとfeed-platform-webのOAuth連携が適切に行われていることを確認しました。

## 検証手順

1. ローカルDB（Turso）を起動
2. identity-provider、feed-platform-backend、feed-platform-webを起動
3. Playwrightを使用して自動ブラウザ検証を実行
4. Magic Link認証 → OAuth認証コードフロー → ダッシュボード表示を自動化

## IdP ページ一覧

### 1. ログイン画面 (/login)

Magic Linkによるメールアドレス入力画面。

![ログイン画面](screenshots/01-idp-login.png)

### 2. Passkeyログイン画面 (/login/passkey)

Passkeyを使用したログイン画面。

![Passkeyログイン](screenshots/02-idp-login-passkey.png)

### 3. メール確認画面 (/login/check-email)

Magic Link送信後の確認画面。

![メール確認画面](screenshots/03-idp-check-email.png)

### 4. アカウント画面 (/app/account)

ログイン後のアカウント情報表示画面。

![アカウント画面](screenshots/05-idp-account.png)

### 5. Passkey登録画面 (/app/passkey/register)

Passkeyの登録画面。

![Passkey登録画面](screenshots/06-idp-passkey-register.png)

## Feed Platform Web ページ一覧

### 6. 未認証時のリダイレクト (/app)

未認証状態で `/app` にアクセスすると、IdPのOAuth認可画面にリダイレクトされる。

![未認証時リダイレクト](screenshots/04-feed-app-unauthorized.png)

### 7. ダッシュボード (/app)

OAuth認証完了後のダッシュボード画面。

![ダッシュボード](screenshots/08-feed-app-authenticated.png)

### 8. ログアウト後 (/app/logout)

ログアウト後、セッションが破棄され再び未認証状態に戻る。

![ログアウト後](screenshots/09-feed-app-after-logout.png)

## 連携フロー検証

1. **Magic Link認証**: IdPでMagic Linkによるメール認証が正常に動作
2. **OAuth認可コードフロー**: feed-platform-webからIdPへのOAuth認可が正常に完了
3. **セッション管理**: IdPとfeed-platform-webの両方でセッションCookieが適切に設定
4. **ログアウト**: feed-platform-webからのログアウトが正常に動作

## 備考

- oauth-consent画面は現時点で不要なため、スキップ設定が有効になっている
- ローカル環境ではメール送信がmockされ、サーバーログに出力される
