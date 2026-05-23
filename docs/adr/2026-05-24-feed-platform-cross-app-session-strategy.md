---
confirmed: true
scope: roadmap:feed-platform
---

# ADR: feed-platform cross-app セッション戦略 (OAuth 2.1 PKCE + JWT Cookie BFF)

- **Filed at:** 2026-05-24
- **Filer:** implementer (ms-02 Wave 2)
- **Originating step:** ms-02 (Authentication — Passkey + Magic Link) implementation
- **Storage path:** docs/adr/2026-05-24-feed-platform-cross-app-session-strategy.md

## Status

`Accepted` — ms-02 で確定。feed-platform-web / feed-platform-backend 間のセッション伝達方式として採用。

## Context

`docs/adr/2026-05-05-identity-provider-and-authn-authz-architecture.md` (D-4) で「JWT Bearer をセッション伝達手段として採用」「Web フロントは HttpOnly Cookie に JWT を保持し、API コール時に Authorization: Bearer として付け替える」方針が確定した。ms-02 ではこの方針を具体的な実装として確定させる必要があった。

**要件**:
- IdP (Better Auth, OAuth 2.1 AS) と consumer (feed-platform-web) が異なる Cloudflare Worker として動作する
- Web フロント (feed-platform-web) がブラウザ経由のユーザ操作を受け付ける
- feed-platform-backend は feed-platform-web から Bearer トークンを受け取り JWT を検証する
- XSS による JWT 窃取を防止すること
- CSRF 対策を行うこと

## Decision

### D-1: OAuth 2.1 Authorization Code + PKCE フロー採用

| Option                          | 概要                                                         | 採否     | 理由                                                                 |
| ------------------------------- | ------------------------------------------------------------ | -------- | -------------------------------------------------------------------- |
| OAuth 2.1 Authorization Code + PKCE | IdP へリダイレクト → code 取得 → PKCE verifier でトークン交換 | **採用** | OAuth 2.1 標準、公共クライアント向け PKCE 必須、CSRF は state で防止 |
| Implicit フロー                 | code 交換なしでトークンを直接返す                           | 却下     | OAuth 2.1 では Implicit フロー廃止                                   |
| Password フロー                 | credential を直接送信                                        | 却下     | フィッシング耐性なし、OAuth 2.1 では廃止                             |

### D-2: JWT を HttpOnly Cookie に格納 (Cookie-to-Bearer BFF パターン)

| Option                     | 概要                                                              | 採否     | 理由                                                                              |
| -------------------------- | ----------------------------------------------------------------- | -------- | --------------------------------------------------------------------------------- |
| HttpOnly Cookie + BFF 変換 | JWT を HttpOnly SameSite=Lax Cookie に保存、バックエンド呼び出し時に Bearer に変換 | **採用** | XSS で JS から読み取り不可、CSRF は SameSite=Lax + state で軽減             |
| localStorage               | JWT を localStorage に保存                                        | 却下     | XSS で読み取り可能、セキュリティリスク高                                         |
| sessionStorage             | JWT を sessionStorage に保存                                      | 却下     | タブ間共有不可、XSS リスクは localStorage と同等                                 |
| Cookie をそのまま backend へ | Cookie ヘッダをバックエンドへ転送                                | 却下     | feed-platform-backend は別 Worker origin のため Cookie が到達しない              |

### D-3: Cookie-to-Bearer 変換の実装

`js/package/auth-helper/src/cookie-translator.ts` の `extractBearerFromCookie(cookieName, cookieHeader)` が `Cookie` ヘッダ文字列から `feed-session` cookie を抽出し `Authorization: Bearer <token>` 文字列を返す。`js/app/feed-platform-web/app/feature/api/client.ts` (BackendClient) がこの関数を呼び出し、バックエンドへの fetch に Authorization ヘッダを付与する。

### D-4: JWT 検証方式

consumer (feed-platform-web / feed-platform-backend) は `jose` ライブラリの `createRemoteJWKSet` + `jwtVerify` で IdP の JWKS エンドポイント (`/api/v1/auth/jwks`) から公開鍵を取得して署名検証を行う。

```
algorithms: ['ES256']
audience: FEED_PLATFORM_AUDIENCE (env var)
issuer: IDP_BASE_URL (env var)
```

`AppJWTPayload` は `{ sub: string, email: string, iat?: number, exp?: number }` (iat/exp は任意 — 将来の短命トークン対応のため optional)。

### D-5: CSRF 対策

OAuth 2.1 フロー開始時に cryptographically random な `state` 値を生成し、HttpOnly Cookie (`oauth_state`) に保存。コールバック時に query parameter の `state` と Cookie の `oauth_state` を比較する。一致しない場合は 403 を返す。

## Consequences

- **Newly added:** `js/app/feed-platform-web/app/feature/auth/` に oauth-client.ts / callback.ts / middleware.ts / constants.ts が実装された。`js/app/feed-platform-backend/src/feature/auth/` に jwt.ts / middleware.ts が実装された。`js/package/auth-helper/` に extractBearerFromCookie が実装された
- **Existing impact:** feed-platform-web の全ルートに authMiddleware が適用される。未認証ユーザの `/dashboard` アクセスは `/login` にリダイレクトされる
- **Constraints going forward:**
  - `feed-session` cookie name は auth-helper の `FEED_SESSION_COOKIE` 定数で一元管理。変更する場合は全 consumer の参照箇所を合わせて変更する
  - `AppJWTPayload.iat` / `AppJWTPayload.exp` は optional であるため、expiry チェックは `jose` の `jwtVerify` に委ねる (手動 isNumber ガードを追加しない)
  - JWKS キャッシュは `createRemoteJWKSet` のデフォルト動作に依存。TTL 調整が必要な場合は `jwks.ts` の `cacheMaxAge` オプションで制御する

## Related

- [identity-provider と authn/authz アーキテクチャ](./2026-05-05-identity-provider-and-authn-authz-architecture.md)
- [feed-platform 認証プロバイダとして Better Auth を採用](./2026-05-24-feed-platform-auth-provider.md)
- [feed-platform Magic Link 戦略](./2026-05-24-feed-platform-magic-link-strategy.md)
