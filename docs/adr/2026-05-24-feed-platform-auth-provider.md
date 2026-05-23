---
confirmed: true
scope: roadmap:feed-platform
---

# ADR: feed-platform 認証プロバイダとして Better Auth を採用

- **Filed at:** 2026-05-24
- **Filer:** implementer (ms-02 Wave 2)
- **Originating step:** ms-02 (Authentication — Passkey + Magic Link) implementation
- **Storage path:** docs/adr/2026-05-24-feed-platform-auth-provider.md

## Status

`Accepted` — ms-02 (feed-platform-ms-02-auth-passkey-magiclink) で確定。identity-provider の OAuth 2.1 プロバイダ実装は本 ADR の決定事項を前提として進行する。

## Context

`docs/adr/2026-05-05-identity-provider-and-authn-authz-architecture.md` (D-1〜D-6) において、認証認可の 4 構成要素 (クライアント / IdP / リソースサーバ / PDP) と JWT Bearer セッション方式が確定した。ms-02 では IdP (`js/app/identity-provider/`) に具体的な認証バックエンドライブラリを導入する必要があり、以下の要件が制約として存在した。

**要件**:
- Cloudflare Workers 上で動作すること (= Node.js ランタイム依存不可、Edge Runtime 互換)
- Passkey (WebAuthn) および Magic Link の双方を組み込みサポートすること
- OAuth 2.1 Authorization Server (認可サーバ) として機能できること
- JWT (ES256) の JWKS エンドポイントを提供できること
- TypeScript-native でありコードベースとの型統合が容易であること
- self-hosted であること (= 外部 SaaS に認証データを預けない)

## Decision

### D-1: Better Auth を OAuth 2.1 プロバイダとして採用

| Option      | 概要                                                                 | 採否     | 理由                                                                                                             |
| ----------- | -------------------------------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------- |
| Better Auth | TypeScript-native OSS 認証ライブラリ。Cloudflare Workers 対応、plugin 式拡張 | **採用** | Edge Runtime 完全対応、passkey / magicLink / oauthProvider / jwt プラグインが built-in、self-hosted、型安全 |
| Auth0       | 外部 SaaS 認証プラットフォーム                                        | 却下     | per-MAU 課金、認証データが外部サービスに保存される、monorepo インフラ外のコントロール不可           |
| Keycloak    | OSS IdP (Java/JVM ベース)                                            | 却下     | JVM 依存のため Cloudflare Workers 上での動作不可、重い ops オーバーヘッド                                   |
| Clerk       | 外部 SaaS 認証プラットフォーム (Next.js 特化寄り)                    | 却下     | 外部 SaaS、self-hosting 制限あり、独自 UI コンポーネントが Remix v3 スタックと競合する                       |

### D-2: 採用 Plugin 構成

`js/app/identity-provider/app/feature/auth/better-auth.ts` に以下のプラグインを有効化した。

```
passkey       — WebAuthn Passkey 登録・認証
magicLink     — Magic Link 電子メール認証
oauthProvider — OAuth 2.1 Authorization Server 機能
              - loginPage: '/login'
              - consentPage: '/oauth/consent'
              - cachedTrustedClients: new Set(['feed-platform-web'])
              - scopes: ['openid', 'profile', 'email']
jwt           — JWKS エンドポイント提供 (ES256)
              - jwks.keyPairConfig.alg: 'ES256'
```

JWKS エンドポイント: `/api/v1/auth/jwks` (consumer が `createRemoteJWKSet` で参照)

### D-3: DB バックエンド

Better Auth のセッション / ユーザ / OAuth アプリケーション情報は Turso/LibSQL (Kysely) に格納する。スキーマは Atlas (`atlas.hcl` / `db/schema.hcl`) で管理し、型は atlas-to-kysely で生成する (`app/feature/db/generated.ts`)。

## Consequences

- **Newly added:** `js/app/identity-provider/` に Better Auth 設定 (`app/feature/auth/better-auth.ts`)、Turso/LibSQL Kysely 層 (`app/feature/db/kysely.ts`)、Atlas マイグレーション (`db/migrations/`)、Email 送信層 (`app/feature/email/`) が実装された
- **Existing impact:** identity-provider はすべての認証フロー (Passkey / Magic Link / OAuth 2.1) を Better Auth 経由で提供する。Better Auth の major version up は breaking change になりうるため、依存バージョンを固定管理する
- **Constraints going forward:**
  - OAuth 2.1 の scope は `openid profile email` のみ。ms-03 (RBAC) で scope 追加が必要な場合は本 ADR の Decision を更新する
  - `cachedTrustedClients` は現在 `feed-platform-web` 固定。新 consumer 追加時はここに追記する
  - jwt plugin の alg は `ES256` 固定。変更する場合は consumer 側 JWKS 検証ロジックの更新が必要

## Related

- [identity-provider と authn/authz アーキテクチャ](./2026-05-05-identity-provider-and-authn-authz-architecture.md)
- [feed-platform cross-app セッション戦略](./2026-05-24-feed-platform-cross-app-session-strategy.md)
- [feed-platform Magic Link 戦略](./2026-05-24-feed-platform-magic-link-strategy.md)
