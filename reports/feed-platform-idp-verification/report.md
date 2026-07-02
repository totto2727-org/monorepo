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

**総合評価: ✅ OAuth連携とBackend連携は正常に動作**

IdPとfeed-platform-webのOAuth連携、およびfeed-platform-webからBackend (BFF) へのユーザー情報取得が適切に行われていることを確認しました。

ただし、`/app/logout` 後の最終表示はログイン画面ではなくDashboardでした。画像上は `Logged in as: test@example.com` と `Logout` が見えているため、「ログアウト後に未認証画面が表示された」とは判定していません。

## 検証手順

1. ローカルDB（Turso）を起動
2. identity-provider、feed-platform-backend、feed-platform-webを起動
3. Playwrightを使用して自動ブラウザ検証を実行
4. Magic Link認証 → OAuth認証コードフロー → ダッシュボード表示を自動化

## 画像検証フェーズ

スクリーンショット取得後、画像そのものを確認し、表示内容とレポート記述が一致しているかを検証しました。

| スクリーンショット              | 画像上の主要表示                                                           | 判定                                                     |
| ------------------------------- | -------------------------------------------------------------------------- | -------------------------------------------------------- |
| `04-feed-app-unauthorized.png`  | `ログイン`, `メールアドレス`, `マジックリンクを送信`, `Passkey でログイン` | ✅ 未認証時のIdPログインリダイレクト                     |
| `08-feed-app-authenticated.png` | `Dashboard`, `Logged in as: test@example.com`, `Subject: ...`, `Logout`    | ✅ 認証済みDashboard                                     |
| `09-feed-app-after-logout.png`  | `Dashboard`, `Logged in as: test@example.com`, `Subject: ...`, `Logout`    | ⚠️ ログアウト後の最終表示もDashboard。未認証画面ではない |

## 修正点

検証中に `feed-platform-web` の `BACKEND_BASE_URL` が `localhost` と `127.0.0.1` で混在しており、Backend への接続で `Transport error` が発生していました。以下のファイルを修正して統一しました：

- `js/app/feed-platform-web/wrangler.jsonc`: `BACKEND_BASE_URL` を `http://127.0.0.1:8788` に変更
- `js/app/feed-platform-web/app/feature/env.ts`: `devLayer` の `BACKEND_BASE_URL` を `http://127.0.0.1:8788` に変更

`IDP_BASE_URL` は Cookie 共有の観点から `localhost` のままにしています。

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

OAuth認証完了後のダッシュボード画面。Backend (BFF) からユーザー情報を取得して表示している。

![ダッシュボード](screenshots/08-feed-app-authenticated.png)

### 8. ログアウト後 (/app/logout)

`/app/logout` はfeed-platform-web側のサインアウト処理後に `/app` へリダイレクトする。取得画像では最終表示がDashboardで、`Logged in as: test@example.com` と `Logout` が見えている。

そのため、この画像は「ログアウト後に未認証状態へ遷移した」証跡ではなく、「ログアウト後の最終表示がDashboardになっている」証跡として扱う。

![ログアウト後](screenshots/09-feed-app-after-logout.png)

## 連携フロー検証

1. **Magic Link認証**: IdPでMagic Linkによるメール認証が正常に動作
2. **OAuth認可コードフロー**: feed-platform-webからIdPへのOAuth認可が正常に完了
3. **セッション管理**: IdPとfeed-platform-webの両方でセッションCookieが適切に設定
4. **Backend連携**: BFF経由で `/api/v1/me` からユーザー情報を正常に取得
5. **Logout表示確認**: `/app/logout` 後の最終画面はDashboard。ログアウト成功画面としては判定しない

## 備考

- oauth-consent画面は現時点で不要なため、スキップ設定が有効になっている
- ローカル環境ではメール送信がmockされ、サーバーログに出力される
- `localhost` と `127.0.0.1` の混在は Cookie ドメインおよび fetch の接続性に影響するため注意が必要
