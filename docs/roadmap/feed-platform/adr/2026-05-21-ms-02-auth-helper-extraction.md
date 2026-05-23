---
confirmed: true
scope: roadmap:feed-platform
---

# ADR: feed-platform 共通ライブラリ抽出 (auth-helper)

- **Filed at:** 2026-05-21
- **Filer:** implementer (ms-02 Wave 5) — `confirmed: true` 確定 (2026-05-21)
- **Originating step:** ms-02 (Authentication) Wave 5 implementation
- **Storage path:** docs/roadmap/feed-platform/adr/2026-05-21-ms-02-auth-helper-extraction.md

## Status

Accepted

## Context

`feed-platform` ロードマップの ms-02 (Authentication) は 3 consumer projects (`identity-provider` / `feed-platform-backend` / `feed-platform-web`) にまたがって JWT セッション認証フローを実装する。Wave 1〜4 の漸進的実装の結果、認証フロー基盤要素である以下 3 種が **3 プロジェクトに完全同形コピー** された状態となった (= ms-01 Phase 1 で観測されたものと同種の DRY 違反):

- `AppJWTPayload` 型 (`{ readonly sub: string; readonly iat: number; readonly exp: number }`) — JWT セッション payload の型定義 (feed-platform-backend / feed-platform-web で重複)
- `FEED_SESSION_COOKIE` 文字定数 (`'feed-session'`) — HttpOnly session cookie の名前 (identity-provider に定義、feed-platform-web ではハードコード)
- `extractBearerFromCookie` 純関数 — `Cookie` ヘッダから指定 cookie を抽出し `Authorization: Bearer <token>` 形式に変換する pure function (feed-platform-backend / feed-platform-web で重複)

加えて identity-provider 側の OAuth 2.1 endpoint base path (`'/api/v1/auth/oauth'`) も将来 consumer 側 (feed-platform-web のリダイレクト処理等) が参照する可能性が高く、文字列定数として共有化対象に含める。

本 ADR は ms-01 Phase 2 ADR (`2026-05-08-shared-libraries-extraction.md`) で確立された抽出基準を再適用したものとして位置づける:

- **zero runtime deps** (peer / runtime dep を持たず、型 + 定数 + 純関数のみで完結)
- **factory-only でない単純抽出** (型/定数/関数を namespace 化せず直接 export)
- **責務スコープを単一の関心事に閉じる** — 本 ADR では authentication (authn) 補助に限定

ms-02 Wave 5 (Cleanup / Refactor) の最終工程として、上記重複を `js/package/auth-helper/` に集約し各 consumer の local 定義を削除する判断を確定する。

## Decision

### D-1: `js/package/auth-helper/` 新設

`js/package/` 配下に新規 library package `auth-helper` を配置する。既存 `effect-hono` / `remix-helper` と同形の `private: true` + scope なし flat name (ms-01 Phase 2 ADR D-1 の命名規約を継承)。

### D-2: export surface

barrel `src/index.ts` から以下 4 シンボルのみを公開する:

- **`AppJWTPayload`** (type, `src/jwt-payload.ts`): JWT セッション payload の interface (`sub` / `iat` / `exp`、すべて `readonly`)
- **`FEED_SESSION_COOKIE`** (constant, `src/constants.ts`): `'feed-session'` — feed-platform-web ↔ feed-platform-backend 間 HttpOnly session cookie name
- **`OAUTH_BASE_PATH`** (constant, `src/constants.ts`): `'/api/v1/auth/oauth'` — identity-provider OAuth 2.1 endpoint base path
- **`extractBearerFromCookie`** (pure function, `src/cookie-translator.ts`): `(cookieName: string, cookieHeader: string | undefined) => string | null` — `Cookie` ヘッダから指定 cookie 値を抽出し `Bearer <token>` 文字列に変換、未検出時は `null`

barrel re-export は `oxlint-disable-next-line oxc/no-barrel-file` 指示で意図を明示する (= 3 module を 1 entry に集約する意図的バレル)。

### D-3: zero-runtime-dep policy

`auth-helper` は **`package.json` に `dependencies` / `peerDependencies` を一切持たない**。tsconfig のみ extends `@totto2727/fp/tsconfig/vite` で型側 dev tooling は継承する。理由:

- 公開 API は型 + 文字列定数 + 純関数のみで構成される
- runtime dep を導入すると後述の authz package との責務分離が曖昧化する
- consumer の bundling 戦略 (Cloudflare Workers / Remix Vite plugin) に対し中立であり続ける

将来的に Effect 依存の helper (例: `Effect.gen` 化された JWT 検証フロー) を追加する場合、それは本 package には入れず別 package に切り出すこととする (= zero-runtime-dep 原則を破る変更を `auth-helper` に accumulation させない)。

## Consequences

### Newly added

- **`js/package/auth-helper/`** が `package.json` (`name: "auth-helper"` / `private: true` / `type: module` / no `dependencies` / no `peerDependencies`) + `tsconfig.json` (extends `@totto2727/fp/tsconfig/vite`) + `src/{index,constants,cookie-translator,jwt-payload}.ts` で配置される
- library API surface: `AppJWTPayload` (type) / `FEED_SESSION_COOKIE` (constant) / `OAUTH_BASE_PATH` (constant) / `extractBearerFromCookie` (pure function) の 4 symbol

### Existing impact

- **`identity-provider`**: 旧 local 定義 `FEED_SESSION_COOKIE` を削除し `auth-helper` import に切替
- **`feed-platform-backend`**: 旧 local `AppJWTPayload` 型 (`src/feature/auth/` 配下) を削除し `auth-helper` import に切替
- **`feed-platform-web`**: 旧 local `AppJWTPayload` 型 + ハードコードされた cookie 名 `'feed-session'` を削除し `auth-helper` 経由 (`FEED_SESSION_COOKIE` 定数) に切替
- **`pnpm-workspace.yaml`**: 既存 `js/package/*` glob で新規 package が自動取り込み (catalog 定義変更不要、ms-01 Phase 2 ADR D-1 と同条件)
- **既存 CI (`vp run --parallel ci`)**: 追加変更なしで本 library + 3 consumer を取り込む

### Future constraints

- **責務スコープ厳守: authn 補助に限定する**

  `auth-helper` は **authentication (authn) 補助** = 認証フロー補助の純関数 / 型 / 定数のみを範囲とする。具体的には JWT payload 型 / session cookie 名 / OAuth endpoint path / cookie header parsing 等の「認証 token を運ぶための周辺ユーティリティ」に閉じる。

- **ms-03 の authz package と統合しない**

  ms-03 (Authorization) で導入予定の authz package は **Casbin ベースの RBAC ポリシー評価** を責務とする別 package であり、以下の点で `auth-helper` と本質的に異なる:

  | 観点                | `auth-helper` (本 ADR)                       | ms-03 authz package                          |
  | ------------------- | -------------------------------------------- | -------------------------------------------- |
  | 責務カテゴリ        | authentication (authn) 補助                  | authorization (authz) ポリシー評価           |
  | 公開内容            | 型 / 文字列定数 / 純関数                     | Casbin enforcer / RBAC 評価 API              |
  | runtime dependency  | なし (zero-runtime-dep policy)               | あり (Casbin 等のランタイム依存)             |
  | 関心事              | token 形式 / cookie 名 / payload schema      | 役割 / 権限 / リソースアクセス制御           |

  これら 2 package は **責務カテゴリも runtime dep プロファイルも異なる** ため、ms-03 着手時に「両方とも認証関連だから統合する」という判断を行ってはならない。authn の補助情報 (token を運ぶ周辺要素) と authz の意思決定 (権限評価) は別レイヤとして分離維持する。

- **zero-runtime-dep 原則の維持**

  将来 `auth-helper` に Effect / Hono / Remix 等の runtime dep を導入する変更は禁止する。これらに依存する認証 helper が必要になった場合は別 package (例: `effect-auth` 等) に切り出すこととし、本 package の zero-runtime-dep 性質を維持する。

## Related

- **Precedent ADR**: `docs/roadmap/feed-platform/adr/2026-05-08-shared-libraries-extraction.md` (ms-01 Phase 2、`effect-hono` + `remix-helper` 抽出) — 抽出基準 (zero runtime deps + 型/定数/純関数のみ) を本 ADR が継承
- **Phase 1 ADR**: `docs/roadmap/feed-platform/adr/2026-05-05-project-structure-and-runtime.md` — Service tag namespace / runtime 規約 (本 ADR では runtime dep を持たないため直接の継承関係はないが、monorepo 内 architectural constraints として継続有効)
- **Forward reference**: ms-03 (Authorization) cycle にて Casbin ベース authz package を別途新設予定 (本 ADR Consequences の「責務スコープ厳守」節を参照)
