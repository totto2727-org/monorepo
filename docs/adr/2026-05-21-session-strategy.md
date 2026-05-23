---
confirmed: true
scope: general
---

# ADR: セッション保持戦略 (DB session + JWT + httponly Cookie)

- **Filed at:** 2026-05-21
- **Filer:** implementer (Step 6)
- **Originating step:** dev-workflow Step 6 (Implementation) of cycle `feed-platform-ms-02-passkey-magic-link`
- **Storage path:** docs/adr/2026-05-21-session-strategy.md

## Status

`Accepted` — ms-02 (`feed-platform-ms-02-passkey-magic-link`) で確定。セッション保持戦略はクライアント / `identity-provider` / リソースサーバの 3 経路にまたがるため、ADR `2026-05-05-identity-provider-and-authn-authz-architecture.md` (D-1 / D-2 / D-3) と同様、本リポジトリで認証認可を要する将来の他システムにも影響する。このため General mode (`docs/adr/`) に配置し、`scope: general` で保存する。

## Context

ADR `2026-05-05-identity-provider-and-authn-authz-architecture.md` で以下が確定済:

- **D-1**: 認証認可の 4 構成要素 (クライアント / 基幹サーバ / リソースサーバ / 共有 authz パッケージ) と JWT 発行経路
- **D-2**: JWT 送信方法 (ブラウザ ↔ Web フロントサーバは Cookie、Web フロントサーバ → リソースサーバは Bearer)
- **D-3**: リソースサーバは Authorization ヘッダー由来の JWT のみで認証する (Cookie を一切受理しない)

さらに `docs/roadmap/feed-platform/design-hint.md` §H で Cookie 属性の素案が示され、その中で **Cookie の `httponly` 属性採用判断は ms-02 に委譲** とされていた。

ms-02 で Passkey / Magic Link 認証フローを実装するにあたり、以下 3 点を 1 つの決定束として確定する必要が生じた:

1. **`identity-provider` 側のセッション保持**: Better Auth の DB session (`session` テーブル) を採用するか / JWT のみで stateless 化するか
2. **Web フロントエンド側のセッション保持**: ブラウザ ↔ Web フロントサーバ間の Cookie の属性 (特に `httponly`) を確定する
3. **リソースサーバ側の受理**: ADR D-3 を遵守し Bearer のみで認証する経路を実装上明確化する

これら 3 点は **トリプル構成 (IdP DB session + JWT 発行 + httponly Cookie)** として組み合わせると、SoT を `identity-provider` DB に集約しつつ通常リクエスト経路を JWT 検証のみで完結させる構造が成立する。本 ADR でこのトリプル構成を確定する。

## Decision

本 ADR は 3 つの決定事項 (D-1〜D-3) を 1 つの決定束として確定する。各決定はそれ単体で機能するが、合わせて「SoT = IdP DB session / JWKS 分散検証 / リソースサーバ Bearer-only / 通常経路で IdP roundtrip なし」というセッション戦略を構成する。

### D-1: `identity-provider` 側 = Better Auth DB session (session table) + JWT (ES256, JWKS 公開)

`identity-provider` は Better Auth の **DB session** (= `session` テーブルに永続化されるサーバサイドセッション) を SoT として保持しつつ、その session を裏付けとして **JWT (ES256 署名)** を発行する。JWT は `jwt` plugin + `oauthProvider` plugin の組み合わせで OAuth 2.1 フロー経由で発行され、検証鍵は **JWKS endpoint** から公開される。

- **session テーブル (Better Auth 管理)**: ユーザのログイン状態を永続化し、ログアウト / revoke 操作で即時に DB レコード削除して無効化できる (= SoT)
- **JWT (ES256)**: session の派生物として発行され、リソースサーバへの Bearer 送信に用いる。署名は ES256 (= 楕円曲線署名)、検証鍵は JWKS endpoint で公開し、リソースサーバはこれをキャッシュして in-memory で検証する
- **`jwt` + `oauthProvider` plugin**: Better Auth の `jwt` plugin が JWT 発行 / JWKS 公開を担い、`oauthProvider` plugin が OAuth 2.1 認可コードフロー (PKCE) を提供する
- **根拠 (DB session 採用)**: revoke 即時性 (DB delete で即時失効) と、JWT のみで stateless 化した場合の失効困難性 (= 短期 TTL + blacklist 等の追加機構が必要) のトレードオフを比較し、SoT 集約による運用容易性を優先

### D-2: Web フロントエンド側 = `feed-session` Cookie (httponly=true, Secure=true, SameSite=Lax, Path=/)

ブラウザ ↔ Web フロントエンドサーバ (`feed-platform-web`) 間は **`feed-session` Cookie** で JWT を保持する。Cookie 属性は以下に確定する。

| 属性       | 値      | 理由                                                                                                  |
| ---------- | ------- | ----------------------------------------------------------------------------------------------------- |
| `httponly` | `true`  | XSS 起因の JWT 漏洩を水際で抑止。BFF パターンにより JS から JWT を直接操作する必要がない (= ペナルティなし) |
| `Secure`   | `true`  | 本番環境では HTTPS のみ送信。平文経路での Cookie 漏洩を遮断                                            |
| `SameSite` | `Lax`   | CSRF 主経路を遮断しつつ、リンク遷移 (= GET ナビゲーション) は許可。標準的なバランス                  |
| `Path`     | `/`     | サイト全体で Cookie 送信。BFF (`/api/*`) と SSR (`/*`) の両経路で利用する                              |
| `Domain`   | (暗黙)  | 暗黙設定 (= Cookie 発行ドメインのみ送信)。subdomain 横断送信を意図的に発生させない                  |

- **`httponly=true` 採用の根拠**:
  - ADR `2026-05-05-...` D-2 で確定した **BFF パターン (Cookie ↔ Bearer 翻訳)** により、Web フロントサーバが Cookie から JWT を取り出して Bearer ヘッダーに付け替えてリソースサーバに転送する。**クライアント側 JS が JWT を直接扱う必要が存在しない**
  - JS から JWT を読めない (= `document.cookie` でアクセス不可) ため、XSS による JWT 抽出の主経路を遮断できる
  - design-hint.md §H で示された素案 (httponly=true default) と整合
- **`Secure=true` / `SameSite=Lax` 採用の根拠**: design-hint.md §H 素案 + OWASP Cookie Security ガイドライン準拠

### D-3: リソースサーバ側 = Cookie 受理せず Bearer JWT のみ (ADR D-3 遵守)

リソースサーバ (`feed-platform-backend`) は **Cookie を一切受理せず**、`Authorization: Bearer <JWT>` ヘッダー由来の JWT のみで認証する。Cookie 付きリクエストが到達した場合は Cookie を無視し、Bearer が無ければ **401 Unauthorized** を返す。

- **根拠**: ADR `2026-05-05-identity-provider-and-authn-authz-architecture.md` D-3 (信頼境界の Authorization ヘッダー一本化) の遵守。Cookie ↔ Bearer 翻訳責務は Web フロントサーバ (BFF) に閉じ、リソースサーバはどのクライアント種別 (Web / Mobile / CLI) からも同一経路で扱う
- **副次効果**: CSRF 攻撃の主経路 (Cookie 自動送信) がリソースサーバに到達しないため、リソースサーバ側で CSRF 対策コードを書く必要がない

### Alternatives considered

| Option          | Summary                                                                                                                            | Adopted / Rejected | Rationale                                                                                                                                                                       |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A** (Adopted) | IdP DB session + JWT (ES256, JWKS 公開) + `feed-session` Cookie (httponly=true, Secure=true, SameSite=Lax) + リソースサーバ Bearer-only | Adopted            | SoT = DB session (revoke 即時) / JWKS 分散検証 (通常経路で IdP roundtrip なし) / XSS 主経路遮断 / ADR D-3 遵守                                                                                                                              |
| **B**           | DB session なしの JWT-only (stateless) で `identity-provider` 側を構成                                                              | Rejected           | revoke 即時性が失われ、blacklist / 短期 TTL + refresh の追加機構が必要になる。SoT が分散し運用負荷が増大                                                                                                |
| **C**           | Cookie の `httponly=false` を採用してクライアント JS から JWT を操作可能にする                                                       | Rejected           | XSS 起因の JWT 漏洩経路を開ける。BFF パターンが成立する以上、クライアント JS が JWT を直接扱う必要は存在せず、`httponly=true` を採用しないペナルティが存在しない                                                                                                                                                                                                                |
| **D**           | リソースサーバが Cookie も受理する (Bearer + Cookie の両受理)                                                                       | Rejected           | ADR `2026-05-05-...` D-3 (信頼境界の Authorization ヘッダー一本化) に反する。CSRF 対策コードがリソースサーバ側に必要となり、信頼境界が曖昧化                                                                                              |

## Consequences

### Newly added

- **`session` テーブルが Better Auth 管理下に確定**: `identity-provider` の DB に Better Auth が `session` / `account` / `user` / `verification` 等を自動 migration する。`session` テーブルが SoT として運用される
- **JWT 発行経路の確定**: `jwt` plugin + `oauthProvider` plugin により ES256 署名 JWT が OAuth 2.1 認可コードフロー経由で発行され、JWKS endpoint が `identity-provider` 内で公開される
- **`feed-session` Cookie が `feed-platform-web` で設定 / 削除される**:
  - 発行: OAuth 認可コード受理後のコールバックハンドラ (`app/feature/auth/callback.ts` 相当) で `httponly=true / Secure=true / SameSite=Lax / Path=/` 属性付きで設定
  - 削除: `/logout` ルートで Cookie をクリア (= Max-Age=0 or expired Set-Cookie)
- **BFF Cookie ↔ Bearer 翻訳ミドルウェア**: `feed-platform-web` 内の middleware が Cookie から JWT を抽出し、リソースサーバ呼び出し時に Bearer ヘッダーに付け替える
- **リソースサーバの Bearer-only 認証ミドルウェア**: `feed-platform-backend` の `src/feature/auth/middleware.ts` が Cookie を無視し、Bearer JWT のみで認証する。JWKS をキャッシュして in-memory で JWT を検証する

### Existing impact

- **ADR `2026-05-05-...` D-1〜D-3 と整合**: 本 ADR は D-1〜D-3 の具体実装パラメータ (DB session 採用 / Cookie 属性 / Bearer-only) を確定するもので、上位 ADR の決定を覆さない
- **`feed-platform-backend` の middleware**: 本 ADR D-3 を遵守する形で Cookie 受理コードを実装しない / 既存にあれば削除する
- **将来の他システムへの影響**: `identity-provider` を再利用する将来の他システムも、本 ADR のトリプル構成 (DB session + JWT + httponly Cookie) を引き継ぐことが推奨パスとなる

### Constraints going forward

- **SoT = IdP DB session を維持する**: `identity-provider` の `session` テーブルが session の SoT である原則を将来も維持する。JWT のみで stateless 化することは禁止 (= revoke 即時性を失う)
- **JWT 検証は JWKS 分散方式を維持**: リソースサーバが JWT 検証のたびに `identity-provider` に問い合わせることは禁止 (= 通常リクエスト経路に IdP roundtrip を発生させない)。JWKS キャッシュ + in-memory 検証が必須
- **`feed-session` Cookie の `httponly=true` を維持**: 将来クライアント側 JS から JWT を直接扱う要求が発生した場合は、本 ADR を Superseded する形で別 ADR を起票する。安易に `httponly=false` に変更することは禁止
- **リソースサーバの Cookie 受理禁止**: ADR `2026-05-05-...` D-3 と本 ADR D-3 により、リソースサーバが Cookie を受理することは将来も禁止
- **JWKS rotation の運用設計は ms-10 以降**: 本 ms-02 では JWKS rotation の運用 (= 鍵ローテーション周期 / overlap 期間 / 廃止鍵の取り扱い) は確定しない。ms-10 (運用フェーズ) で別途確定する
- **refresh token は Better Auth 既定**: refresh token の発行 / TTL / 取り扱いは Better Auth 既定値を採用し、本 ms-02 では独自カスタマイズしない。必要に応じて ms-10 以降で調整する

### Trade-offs と緩和策

- **Pros**: SoT = DB session で revoke 即時 / JWKS 分散検証で通常経路に IdP roundtrip なし / XSS 主経路を `httponly=true` で遮断 / CSRF 主経路を `SameSite=Lax` + リソースサーバ Cookie 受理禁止で遮断 / ADR D-1〜D-3 と完全整合
- **Cons**: DB session の存在により `identity-provider` の DB が単一障害点になりうる (= ログイン / トークン更新時に IdP DB が必要) / JWKS rotation の運用設計が将来必要
- **緩和策**: DB session への依存はログイン / トークン更新時のみであり、**通常リクエスト経路 (JWT 検証経路) は IdP に依存しない** (= サーバレス相性最大化原則を満たす)。JWKS rotation 運用は ms-10 以降で別途設計する
