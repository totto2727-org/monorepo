# feed-platform 認証フロー — 将来課題詳細レポート

ms-02 (PR #144) で **OAuth 2.1 PKCE + Magic Link / Passkey + BFF** の標準フロー + ステートレス化を完了。本書は **意図的にスコープ外** とした項目を、後続 PR / マイルストーンで着手しやすいように詳細記述したもの。

各項目は次の構造で記述する:

- **何か** — 仕様 / 概要
- **現状の代替** — なくても回っている理由
- **導入が必要になる条件** — トリガー
- **実装方針** — 着手時の指針
- **見積もり** — 工数の粗い目安 (S=半日 / M=1-3 日 / L=1 週間以上)
- **リスク・考慮事項**
- **参考**

---

## O-1. OIDC ID Token + nonce

### 何か

OpenID Connect Core 1.0 が定める **ID Token** (RFC 7519 形式の JWT) を `/token` レスポンスに含め、認可リクエストに **nonce** クレームを通すことで Replay 攻撃に耐性を持たせる。

- ID Token: ユーザー識別 (`sub`, `email`, `name`, etc.) を改ざん検知付きで運ぶ
- nonce: クライアントが認可リクエストで生成し ID Token の `nonce` クレームに反映、callback で検証

### 現状の代替

- ms-02 は OAuth 2.1 のみで、access_token (JWT) に `sub` / `email` を直接埋め込んでいる
- 識別情報 (`/me` 相当) は backend `/api/v1/me` でセッション保有者の `c.var.user` を返している
- Replay 攻撃は state (CSRF) + PKCE (code 結合) で間接的に防御

### 導入が必要になる条件

- third-party OAuth client を受け入れる (彼らに OIDC 標準を期待される)
- access_token と identity_token を分離したい (アクセススコープ縮小)
- 既存の OIDC ライブラリ (Auth0 SDK 等) と連携する必要性

### 実装方針

1. Better Auth の `oauthProvider` プラグイン設定で `idToken: true` を有効化 (Better Auth が ID Token も同時発行可能)
2. feed-platform-web `/login` で `nonce` を生成して authorize URL に埋め込み (`crypto.randomUUID()` + Cookie に保存)
3. `/auth/callback` で `id_token` を取り出し `nonce` クレームを照合
4. backend は ID Token と access_token を区別 (`aud` で識別可)

### 見積もり

**M** (Better Auth 設定 + feed-platform-web 側の nonce ハンドリング + backend での区別)

### リスク・考慮事項

- ID Token と access_token の `aud` 衝突 → 別 audience 設計が必要
- フロント側で nonce を Cookie に保存するなら HttpOnly + SameSite=Strict 必須
- ステートレス化を維持するなら nonce もクエリ伝搬を検討

### 参考

- [OpenID Connect Core 1.0 §3.1.2.1](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest)
- [RFC 9700 §4.7 (Replay attack)](https://datatracker.ietf.org/doc/html/rfc9700#name-replay-attacks)

---

## O-2. Refresh Token

### 何か

OAuth 2.1 §6 に基づき、access_token 有効期限切れ時にユーザー操作なしで再発行する **refresh_token** を導入する。

### 現状の代替

- access_token JWT (`feed-session` Cookie) の `exp` 切れで即ログアウト
- 再ログインが必要 (1 時間 〜 1 日想定の短命設定であれば許容範囲)

### 導入が必要になる条件

- ユーザー操作なしの長時間セッション (例: バックグラウンド同期、Push 通知)
- アクセストークン短命化 (5〜15 分) + refresh による頻繁な rotation でセキュリティ強化

### 実装方針

1. Better Auth `oauthProvider` で refresh_token 発行を有効化
2. feed-platform-web BFF の `BackendClient` に **401 を受けたら refresh エンドポイントを呼んで再試行** するインターセプターを追加
3. refresh_token は **HttpOnly Cookie 別途** (現状の feed-session JWT と分離) で BFF が保持
4. backend は refresh_token を知らない (BFF のみが知る)
5. refresh エンドポイント (`/api/v1/auth/oauth2/token` with `grant_type=refresh_token`) を BFF が呼び、新 access_token に差し替え

### 見積もり

**L** (BFF 内のリトライロジック + Cookie 設計 + 401 → refresh の race condition 対策)

### リスク・考慮事項

- **Refresh Token Rotation**: 古い refresh_token は使い捨て + 新規発行で交換。Better Auth がサポート確認要
- 並行リクエストで refresh が複数走らないよう mutex 必要
- refresh_token が漏れた場合の影響範囲が大 (再認可フローでの取り消し設計が必要)

### 参考

- [OAuth 2.1 §6](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1)
- [RFC 9700 §2.2.2 (Refresh Token Rotation)](https://datatracker.ietf.org/doc/html/rfc9700)

---

## O-3. PAR (Pushed Authorization Requests, RFC 9126)

### 何か

認可リクエストパラメータ (`client_id`, `redirect_uri`, `scope`, `state`, `code_challenge`, etc.) を `/par` エンドポイントに事前 POST し、`request_uri` で参照する形に変更する。**URL から機微情報を消す**。

```
従来: /authorize?client_id=...&redirect_uri=...&scope=...&state=...&code_challenge=...
PAR:  /authorize?client_id=X&request_uri=urn:ietf:params:oauth:request_uri:abc123
```

### 現状の代替

- 認可パラメータは URL クエリで露出
- HTTP の TLS で暗号化されるが、**ブラウザ history / リファラ / ログ** には残る
- dev / first-party 環境では脅威モデル外

### 導入が必要になる条件

- プロダクション化 (公開ネットワーク経由)
- 監査ログから機微情報を排除したい (PCI DSS, ISO 27001 等)
- third-party client を受け入れて高セキュアな相互運用を求める

### 実装方針

1. Better Auth が PAR をサポートするか確認 (現時点不明 → 拡張プラグインが必要かも)
2. feed-platform-web `/login` で、authorize URL を組み立てる代わりに `POST /par` → `request_uri` を受け取る
3. `/authorize?client_id=X&request_uri=...` で遷移
4. IdP 側で `request_uri` の検証 + パラメータ展開

### 見積もり

**L** (Better Auth に未実装なら IdP 側で別エンドポイント実装が必要)

### リスク・考慮事項

- Better Auth のロードマップに依存
- `request_uri` の TTL 管理 (短命にして再生不可)
- BFF のセッションストレージ (Cloudflare KV / D1 / R2) が必要

### 参考

- [RFC 9126](https://datatracker.ietf.org/doc/html/rfc9126)
- [Better Auth PAR support (要確認)](https://www.better-auth.com/)

---

## O-4. DPoP (Demonstration of Proof-of-Possession, RFC 9449)

### 何か

access_token の **bearer 性質** (持っているだけで使える) を弱め、トークン使用時に **クライアントの秘密鍵で署名された DPoP proof JWT** を添付させることでトークン窃取攻撃に耐性を持たせる。

### 現状の代替

- bearer 型 access_token を HttpOnly Cookie で保護
- BFF パターンで JavaScript から token 取得を不可にしている
- XSS が発生しなければ漏洩しない設計

### 導入が必要になる条件

- API が金銭 / PII / 重要操作を扱う
- mobile / native client の追加 (Cookie が使えない環境)
- セキュリティ監査要件で「token 盗難で API が使い回せない」ことを示す必要

### 実装方針

1. Better Auth が DPoP をサポートするか確認
2. feed-platform-web BFF (and any mobile client) で **WebCrypto** を使い ES256 鍵ペアを生成・保存
3. 認可リクエスト時に DPoP-Bound access_token を要求 (`DPoP` ヘッダ + `jkt` クレーム)
4. backend が各 API リクエストの `DPoP` ヘッダ署名と access_token の `jkt` を照合

### 見積もり

**L+** (鍵管理 + 検証ロジック + Better Auth 拡張)

### リスク・考慮事項

- 鍵保管: BFF は KV / Durable Object に保存できるが Service Worker に保存する案もある
- 検証のレイテンシ増加 (各 API call で署名検証)
- mobile native との互換性

### 参考

- [RFC 9449](https://datatracker.ietf.org/doc/html/rfc9449)

---

## O-5. Back-channel Logout

### 何か

OpenID Connect Back-Channel Logout 1.0。IdP がログアウトイベントを **接続中の全クライアントの logout endpoint に push 通知** することで SSO ログアウトを実現する。

### 現状の代替

- feed-platform-web の `/logout` は IdP `/sign-out` を呼ぶが、**他のクライアント (将来追加) には伝播しない**
- backend は JWT `exp` 検証のみなので IdP セッション無効化を即時反映できない (最悪 JWT 有効期間分遅延)

### 導入が必要になる条件

- 第二、第三の OAuth client を追加 (例: モバイルアプリ、別ドメイン admin)
- 「あらゆる端末からのログアウト」が要件

### 実装方針

1. 各 client の **logout endpoint** を登録 (Better Auth `oauth_application` テーブルに `backchannel_logout_uri` カラム追加)
2. IdP がセッション破棄時に各 client の logout endpoint に **logout_token JWT** を POST (`sub` + `events` クレーム)
3. feed-platform-web BFF が logout endpoint を実装 (`POST /auth/backchannel-logout`)、受け取った `sub` の `feed-session` を破棄
4. backend は **revocation list** (短期 KV / D1) を持ち、revoke された `sub` の JWT を拒否

### 見積もり

**L** (Better Auth 拡張 + 各 client 側の logout endpoint + revocation list)

### リスク・考慮事項

- Cloudflare Workers の KV では eventual consistency なので revocation の即時性が課題
- 各 client が logout endpoint をダウンしている場合の retry / DLQ

### 参考

- [OpenID Connect Back-Channel Logout 1.0](https://openid.net/specs/openid-connect-backchannel-1_0.html)

---

## O-6. Consent screen の運用ポリシー

### 何か

OAuth 2.1 §4.1.2 の Consent (認可同意画面) を実際に運用する。current code はあるが (`/app/oauth/consent`) flow では auto-approve 想定。

### 現状の代替

- IdP は first-party (feed-platform-web のみ) なので consent をスキップ
- 同じ運営元のアプリ = ユーザー視点では実質的に同じサービス

### 導入が必要になる条件

- third-party developer に OAuth API を開放 (Slack / GitHub のような OSS 連携)
- ユーザーの明示的同意ログを残す必要性 (GDPR / 個人情報保護法)

### 実装方針

1. Better Auth `oauthProvider` の `requireConsent` 設定を **client_id ごとに分岐**
   - first-party client → auto-approve
   - third-party client → consent screen 必須
2. consent ログを `consent_log` テーブルに永続化 (用途・期間・取り消し履歴)
3. `/account` ページに「連携アプリ一覧」と「取り消し」UI 追加 (Better Auth `oauth_grant` 表を参照)

### 見積もり

**M** (consent screen の UX 整備 + ログ設計 + 取り消し UI)

### リスク・考慮事項

- consent UX は転換率に直結 → 表示順・文言の慎重設計
- 既存のセッションを巻き戻さずに consent を促す UX

### 参考

- [OAuth 2.1 §4.1.2](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1)

---

## O-7. JWT `aud` の細分化

### 何か

現状すべての backend API call で同じ `aud=feed-platform-web` の JWT を使う。backend が増えたら **audience 別に JWT を発行** する。

### 現状の代替

- backend は 1 つ (`feed-platform-backend`) なので audience 単一で十分
- `JwtService` が `FEED_PLATFORM_AUDIENCE = 'feed-platform-web'` を fix で検証

### 導入が必要になる条件

- 2 つ目の backend (admin API, analytics API, etc.) を追加
- audience 別の権限スコープを実装 (例: admin token は分析 API では使えない)

### 実装方針

1. Better Auth の OAuth token 発行で `scope` パラメータ → `aud` マッピング設計
2. backend ごとに `FEED_PLATFORM_AUDIENCE` 環境変数を個別設定
3. BFF が backend ごとに token を発行 (token exchange RFC 8693 等)

### 見積もり

**M** (OAuth client 設計 + BFF の token store + 各 backend の audience 検証)

### リスク・考慮事項

- BFF が複数の token を保持することで Cookie 数増加
- token exchange の仕様選定 (`urn:ietf:params:oauth:grant-type:token-exchange`)

### 参考

- [RFC 7519 §4.1.3 (aud)](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.3)
- [RFC 8693 (Token Exchange)](https://datatracker.ietf.org/doc/html/rfc8693)

---

## O-8. Better Auth → OAuth callback への直接 302 (1 hop 削減)

### 何か

現状: `Better Auth verify` → `/app/auth/<method>/callback` → `return_to (= /authorize)`

提案: `Better Auth verify` → 直接 `return_to (= /authorize)` (1 hop 削減)

### 現状の代替

- IdP 側の `<method>/callback` ハンドラがクエリ検証 + return_to 解決を担当
- 1 hop 追加するが、ロジック分離の利点あり

### 導入が必要になる条件

- パフォーマンス課題 (callback hop の latency が問題視される)
- callback ハンドラのロジックが完全に不要になった (= return_to 検証も Better Auth 内で行える)

### 実装方針

1. Better Auth の magic-link `callbackURL` に **直接 authorize URL** を渡す (現状は IdP 中継 URL)
2. Better Auth で `callbackURL` の allowlist 検証を強化 (open redirect 防御を Better Auth に委ねる)
3. Passkey は `verify-authentication` 成功時のリダイレクト先を Better Auth が制御できるか確認

### 見積もり

**S-M** (Better Auth 設定変更のみで済むなら S、callbackURL 検証拡張なら M)

### リスク・考慮事項

- Better Auth の `callbackURL` バリデーションが現状の `isSafeReturnTo` と同等以上であることを確認
- IdP のログ可観測性 (callback hop が消えることでデバッグ性低下)

### 参考

- 現状 commit: `2ad0b47c` の `/auth/magic-link/callback` / `/auth/passkey/callback`

---

## 横断的な考慮事項

### CSRF / state の二重防御

- 現状: state パラメータと PKCE code_verifier の両方で攻撃を防御
- O-1 (OIDC) を導入する場合 **nonce** が加わり 3 重防御に
- O-3 (PAR) と組み合わせると state が URL に露出しなくなる

### 鍵管理 (ES256 key rotation)

- IdP の JWT 署名鍵は現状 Better Auth が管理 (具体的な rotation 戦略は未調査)
- backend は JWKS から動的取得するので IdP が `kid` 付きで複数鍵を返せば自動 rotation 可能
- 別 PR で **鍵 rotation 手順** を明文化することを推奨

### 監査ログ

- consent ログ (O-6) と back-channel logout ログ (O-5) は重要監査対象
- Cloudflare Workers 環境では D1 / R2 への永続化を検討

### Cloudflare Workers / Edge 制約

- `crypto` (WebCrypto) は使えるが Node の `crypto` モジュールは使えない (DPoP, nonce 生成で影響)
- KV の eventual consistency が revocation 即時性に影響
- Durable Object を使えば強整合だが latency 増加

---

## 着手優先度の提案

| 優先度 | 項目                      | 理由                                               |
| ------ | ------------------------- | -------------------------------------------------- |
| **高** | O-7 JWT `aud` 細分化      | backend 増加と密接、設計を先に固めると追加コスト小 |
| 高     | O-6 Consent 運用          | UX 設計に時間がかかるため早めの方針決定が有利      |
| 中     | O-1 OIDC ID Token + nonce | OIDC 互換性が必要になった時点で着手                |
| 中     | O-2 Refresh Token         | UX feedback 後判断                                 |
| 中     | O-5 Back-channel Logout   | 第二 client 追加と同時                             |
| 低     | O-3 PAR                   | プロダクション化前の安全性レビュー時               |
| 低     | O-4 DPoP                  | 金銭処理導入時、もしくは API 公開時                |
| 任意   | O-8 callback 1 hop 削減   | 計測してパフォーマンス課題が見えたら               |

---

## 関連ドキュメント

- 現行フロー: [`docs/roadmap/feed-platform/ms-02-login-flow.md`](./ms-02-login-flow.md)
- ステートレス化計画: [`.sisyphus/plans/feed-platform-ms-02-stateless-auth.md`](../../../.sisyphus/plans/feed-platform-ms-02-stateless-auth.md)
- 認証プロバイダ選定 ADR: [`docs/adr/2026-05-24-feed-platform-auth-provider.md`](../../adr/2026-05-24-feed-platform-auth-provider.md)
- クロスアプリセッション ADR: [`docs/adr/2026-05-24-feed-platform-cross-app-session-strategy.md`](../../adr/2026-05-24-feed-platform-cross-app-session-strategy.md)
- Magic Link 戦略 ADR: [`docs/adr/2026-05-24-feed-platform-magic-link-strategy.md`](../../adr/2026-05-24-feed-platform-magic-link-strategy.md)
- ms-02 Retrospective: [`docs/retrospective/feed-platform-ms-02-auth-passkey-magiclink.md`](../../retrospective/feed-platform-ms-02-auth-passkey-magiclink.md)
