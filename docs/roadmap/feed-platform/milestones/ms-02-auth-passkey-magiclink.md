# Milestone: Auth — Passkey + Magic Link 認証

- **Milestone ID:** ms-02-auth-passkey-magiclink
- **Roadmap ID:** feed-platform
- **Status:** completed
- **Created at:** 2026-05-04T00:00:00Z
- **Last updated:** 2026-07-23T00:00:00Z

このドキュメントは `roadmap` の **Step 2 (Milestone Decomposition)** で `roadmap-planner` Specialist が起草する**1 マイルストーンの定義書**。

## 目的

ユーザーが Passkey および Magic Link で認証可能な認証基盤を構築し、後続のすべての機能領域マイルストーン (永続化を除く) が「認証済みユーザー」前提で実装できる土台を成立させる。

## 到達点 (定性)

- ユーザーが Magic Link で初回登録後に Passkey を登録し、次回以降は Passkey でログインできる (実際の Web UI 上で動作確認可能)
- ユーザーが Magic Link でサインアップ・ログインできる (発行されたリンクを踏むとセッションが確立する)
- セッション管理 (発行 / 検証 / 失効) が実装され、後続マイルストーンが「現在のユーザー識別子」を取得できる API 表面が用意されている
- 認証フローのテストケース (正常系・異常系) が成立し、`vp test` で green を維持している
- 認証関連の横断 ADR (Passkey 実装方針 / Magic Link トークン形式 / セッション保持戦略) が `docs/adr/` 配下に確定している

## スコープ

- 対象モジュール: 採用ワークスペース上の認証基盤パッケージ (例: `js/app/feed-platform/auth/` 相当)
- 対象機能: Passkey の登録 / 認証フロー、Magic Link の発行 / 検証フロー、セッション発行 / 検証 / 失効
- 対象ユーザー: 個人開発スコープの単独ユーザー、ただしマルチユーザー前提のスキーマで設計 (RBAC / Organization マイルストーンに引き継ぐため)
- 対象 ADR: Passkey ライブラリ選定、Magic Link 配信経路、セッション保持戦略 (Cookie / JWT / DB セッション 等)

## Current implementation design

This section records the current platform auth design after the shared auth
helper work. Historical ADRs remain unchanged; this milestone note is the
roadmap-level source for the latest codebase state.

- Shared application auth lives in `js/package/auth/`. Older docs and review
  notes may still call this package `auth-helper`, but the current workspace
  package name is `auth`.
- `createBetterAuthSetupMiddleware` in
  `js/package/auth/src/better-auth.ts` owns Better Auth session lookup and
  decoding. It resolves the Better Auth service from the Effect runtime layer,
  reads the session from request headers, maps the Better Auth user into the
  shared app user shape, and stores only `user` in Hono request variables.
- `requireAuthMiddleware` in `js/package/auth/src/require-auth.ts` owns the
  shared require-auth branch. Apps pass only their unauthenticated policy:
  redirects for browser apps and a JSON 401 response for the backend.
- The shared app user shape is `User` in `js/package/auth/src/type.ts` and uses
  `id` plus `email`. This follows Better Auth's native `user.id` field.
- JWT and OIDC payload boundaries keep protocol names. `AppJWTPayload` in
  `js/package/auth/src/jwt-payload.ts` uses `sub`, and translation between
  `sub` and application `id` belongs at that protocol boundary only.
- Shared setup no longer takes app-specific `mapUser` callbacks. If a route or
  protocol needs another shape, it should transform at that boundary rather
  than diverging the shared middleware contract.
- Auth services are not stored in `ctx.var.auth`. Long-lived services stay in
  the Effect runtime/service layer; request context carries request-scoped
  values such as `user`.
- Handlers behind `requireAuthMiddleware` should trust the middleware contract
  instead of repeating defensive `null` checks. If TypeScript cannot see the
  guarantee, fix the shared helper or Hono context typing.

### App boundaries

- `js/app/feed-platform-web/app/feature/auth/middleware.ts` wires
  `createBetterAuthSetupMiddleware` with `BetterAuth.Service` and uses
  `requireAuthMiddleware` to set the return-to cookie and redirect to
  `/app/login`.
- `js/app/feed-platform-backend/src/feature/auth/middleware.ts` wires the same
  setup helper and uses `requireAuthMiddleware` to return a JSON 401 with a
  `WWW-Authenticate` header.
- `js/app/identity-provider/app/feature/auth/middleware.ts` wires the same
  setup helper and uses app-specific redirect policies for normal auth and
  login-session auth.

### Progress notes

- The current codebase has already incorporated the core shared-helper review
  direction: middleware plumbing is centralized, app middleware expresses
  unauthenticated policy, and the app user shape uses `id`.
- The package rename from `auth-helper` to `auth` is now part of the current
  baseline and should be reflected in new docs and coding guidance.
- New users created through Better Auth receive a non-empty initial name before insertion. When the upstream identity has no name, the IdP derives it from the email local part. This removes the need for an onboarding status or a separate name-entry page.
- The local OAuth seed upserts the development user with the non-empty `Dev User` name, so rerunning the seed repairs an existing empty or stale development-user row. Existing non-seed users with empty names are not backfilled.
- Remaining future auth design work should treat historical ADRs as context and
  place new implementation-state corrections in roadmap progress notes rather
  than rewriting adopted ADRs.

## 非スコープ

- RBAC (3 ロール固定) の実装 — `ms-03-auth-rbac-organization` の責務
- Organization (個人 / 汎用) の概念導入 — `ms-03-auth-rbac-organization` の責務
- 期間限定共有 — `ms-04-auth-shared-access` の責務
- OAuth / SAML 等の他認証方式 (Intent 非スコープ)
- 認証情報を要する具体的な業務機能 (フィード取得・配信等) は後続マイルストーンで認証基盤を利用する形で実装

## 依存マイルストーン

- `ms-01-workspace-foundation`: 採用ワークスペース確定とプロジェクト雛形が前提

## 関連 oh-my-codingagent execution サイクル (workflow_identifiers)

| サイクル `<identifier>` | 状態 | コメント |
| ----------------------- | ---- | -------- |
| (未起動)                | -    | -        |

## 想定 oh-my-codingagent execution サイクル数

1 (推奨)

Passkey + Magic Link は同じ「認証フロー基盤」上に並列実装するため単一サイクルで包む。セッション管理も同一サイクル内に含める (認証フロー成立に不可欠なため)。

## 補足 / 留意事項

- 本マイルストーンで導入されるユーザーモデルは、後続 `ms-03-auth-rbac-organization` で Organization / Role 概念を追加できるよう拡張余地を残しておく (User と Organization の関連は ms-03 で確定)
- Passkey 実装は WebAuthn 標準準拠とし、ライブラリ選定は配下 oh-my-codingagent execution サイクル Step 2 (Research) で確定
- Magic Link の配信経路 (メール / 別チャネル) は配下サイクル Step 1 (Intent Clarification) で確定
- New code should treat `js/package/auth/` as the shared auth package: shared setup/require middleware owns Better Auth plumbing, apps provide only unauthenticated policy, app users expose `id`, and `sub` stays at JWT/OIDC payload boundaries.
