# feed-platform ms-02 完成計画 (Auth — Passkey + Magic Link)

## TL;DR

> **Quick Summary**: feed-platform ms-02 は IdP 側の認証バックエンド (better-auth + passkey + magicLink + oauthProvider + jwt) は main に存在するが、IdP UI / web OAuth クライアント / backend Bearer 認証 / 共有 auth-helper / ADR が未マージブランチ (pr5-pr8) に分散している。これらを 5 PR (+任意の E2E PR) に再整理して順次マージし、ms-02 を `completed` にする。
>
> **Deliverables**:
> - PR-A: `js/package/auth-helper/` 共有ライブラリ復活 (constants / cookie-translator / jwt-payload)
> - PR-B: IdP UI ページ 5+1 枚 (login / check-email / login-passkey / register-passkey / account / **oauth-consent (新規)**) + `routes.ts` 更新
> - PR-C: `js/app/feed-platform-web/` OAuth 2.1 PKCE クライアント + callback + middleware + BFF api/client
> - PR-D: `js/app/feed-platform-backend/` Bearer JWT 検証 + middleware + 保護 `/api/v1/me`
> - PR-E: ADR (auth 方針 3 本) + retrospective + progress.yaml ms-02→completed
> - PR-F (任意): playwright e2e (CI 統合)
>
> **Estimated Effort**: Medium (5 PR + ~17 tasks)
> **Parallel Execution**: PR-A と PR-B は並列着手可。PR-C / PR-D は PR-A マージ後に並列。PR-E は全マージ後。
> **Critical Path**: PR-A → (PR-C ∥ PR-D) → PR-E

---

## Context

### Original Request

ms-02-auth-passkey-magiclink の進捗を調査し、残りタスクと PR 分割粒度、各受け入れテストを計画する。IdP は Better Auth を OAuth プロバイダとして稼働。consumer は OAuth ベース。出力は `docs/roadmap/feed-platform/` 配下にコミット。

### Investigation Summary

**Current branches**:
- `main` (HEAD `10087e5c`): IdP backend が main に存在 (pr1-4 マージ済)
- `feat/ms-02-pr5-web-oauth-v2` (未マージ、5 commits ahead): IdP UI + web OAuth が混在
- `feat/ms-02-pr6-backend-rs-v2` (未マージ): backend Bearer 認証
- `feat/ms-02-pr7-auth-helper` (未マージ): 共有ライブラリ。pr5/pr6 が dep 削除して放棄状態
- `feat/ms-02-pr8-adr-progress-v2` (未マージ): ADR + progress

**IdP (main 上で確認)**:
- `app/feature/auth/better-auth.ts` — `passkey` / `magicLink` / `oauthProvider(loginPage:'/login', consentPage:'/oauth/consent', cachedTrustedClients: ['feed-platform-web'], scopes:['openid','profile','email'])` / `jwt(ES256)`
- `app/feature/auth/middleware.ts`
- `app/feature/db/kysely.ts` + `db/migrations/20260518171739_init.sql` (Turso/LibSQL)
- `app/feature/email/{sender,cloudflare,mock}.ts`
- `app/routes.ts` — `FrameName = never` (UI 未登録)
- `app/app.tsx`, `app/feature/runtime/{hono,server}.ts`
- 単体テスト: `kysely.test.ts`, `sender.test.ts`

**main に欠落**:
- IdP UI 全 6 ページ (上記 5 + `/oauth/consent` は全ブランチに無し → 新規)
- feed-platform-web 全 auth ファイル
- feed-platform-backend 全 auth ファイル
- auth-helper 中身
- ADR (auth 関連 0 本) + retrospective + progress 更新

**「中途半端」根因**:
1. pr5 が IdP UI ページと web OAuth クライアントを混載 (本来別 PR にすべき)
2. auth-helper を pr5 (`cddd9e53 inline FEED_SESSION_COOKIE`) / pr6 (`e70deb33 inline AppJWTPayload`) で意図的に dep 削除 → ライブラリ存在意義消失
3. better-auth.ts が `consentPage: '/oauth/consent'` を参照しているが UI が全ブランチに無い
4. cross-app e2e 検証なし

### Self-Review (Metis 相当)

| Question | Answer |
|----------|--------|
| 本当に PR-A を最初に切る必要があるか? | YES — pr5/pr6 が auth-helper を捨てた前提でインライン化されているため、PR-C/D を「auth-helper 復活」で再構築する流れに変えないと、再び放棄される。 |
| pr5 から IdP UI を分離する方法は? | `git checkout -b feat/ms-02-pr4-idp-ui-v2 main && git cherry-pick 510eda87` で `pr5` の特定 commit を抽出。残りの web 部分は別ブランチで rebase。 |
| `/oauth/consent` が無いと cross-app login は動くか? | `cachedTrustedClients` 登録済クライアント (feed-platform-web) は consent skip するため最低限の動作はする可能性。ただし trusted 外クライアント追加時に破綻するため、本マイルストーン内で実装すべき。 |
| `oauth_application` DB row の seed が必要か? | YES — better-auth の OAuth provider は DB の `oauth_application` レコードでクライアント認証する。seed なしでは authorize endpoint が "unknown client" を返す。PR-B (または PR-A) に含めるべき。 |
| WebAuthn を playwright-cli で通せるか? | Chromium DevTools Protocol の `WebAuthn.addVirtualAuthenticator` でテスト可能。E2E PR-F でスクリプト化推奨。手動 playwright-cli では実機 Touch ID/Windows Hello が要求される。 |
| pr8 ADR の中身未確認 | plan には骨子のみ書き executor が PR-E 着手時に内容確定。 |
| 出力先 (`docs/roadmap/feed-platform/`) の問題 | Prometheus 制約により `docs/` 直接書き込み不可。本 plan は `.sisyphus/plans/` に保存し、user が必要なら `docs/` にコピーする方針。 |

---

## Work Objectives

### Core Objective
ms-02-auth-passkey-magiclink を `completed` にする。具体的には、Better Auth を OAuth プロバイダとして稼働する IdP に対し、feed-platform-web と feed-platform-backend が OAuth 2.1 + JWT Bearer で認証連携した状態を main に統合する。

### Concrete Deliverables
- 5 PR (PR-A〜PR-E) すべてマージ済
- 任意 PR-F (E2E) は別 milestone でも可
- `roadmap status feed-platform` で ms-02 が `completed` 表示
- ADR 3 本確定 (`docs/adr/`)
- retrospective 1 本 (`docs/retrospective/feed-platform-ms-02-auth-passkey-magiclink.md`)

### Definition of Done
- [ ] `vp run -r ci` (check + test + build) PASS on main
- [ ] cross-app login (magic link / passkey) が playwright-cli シナリオで全通し
- [ ] feed-platform-backend `/api/v1/me` が unauth=401 / authed=200 を返す
- [ ] ms-02 milestone status = completed (progress.yaml + milestones/ms-02-...md)
- [ ] ADR 3 本 + retrospective が確定

### Must Have
- auth-helper の再有効化 (PR-A) — consumer は auth-helper から定数 / 型を import (インライン NG)
- IdP `/oauth/consent` 実装 (PR-B 新規)
- `oauth_application` の dev seed (PR-A または PR-B)
- 全 PR で vitest + agent QA (playwright-cli または curl/tmux) シナリオ完備
- ADR 3 本 (Better Auth + OAuth 採用 / Cross-app session strategy / Magic Link expiry)

### Must NOT Have (Guardrails)
- インライン化された定数 / 型 (auth-helper 経由必須)
- `console.log` プロダクションコードに残置
- 未使用ファイル (pr5 で commit 530eda87 由来の混在ファイル等)
- secret の commit (`.dev.vars` は `.gitignore`、`.dev.vars.example` のみコミット)
- `as any` / `@ts-ignore` (型安全を担保)
- pr5 / pr6 / pr7 / pr8 ブランチを「マージ単位」として再利用しない (cherry-pick + 再構成が原則)

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** — 全 acceptance は agent が実行可能。

### Test Decision
- **Infrastructure exists**: YES (vitest via `vp test`)
- **Automated tests**: YES (tests-after の方針 — 既存ブランチに test ファイルあり、流用 + 不足分追加)
- **Framework**: `vite-plus/test` (vitest)
- **Style**: 既存パターンに従う (`describe` / `test|it` + `expect`)

### QA Policy
各 PR は以下を満たすこと:
1. **自動テスト**: `vp test run js/<path-to-package>` PASS (root から `vp test` 全体実行でも可)、`vp check` PASS、`vp run --filter <package> build` PASS
   - 注: `vp test --filter` は CLI 構文上存在しない。`vp test run <path>` または `cd <pkg> && vp test` を用いる
2. **Agent QA シナリオ**: 各 PR の Acceptance Criteria に列挙された playwright-cli / curl / tmux シナリオを agent が直接実行 + evidence 保存

### Evidence パス
`.sisyphus/evidence/feed-platform-ms-02/{pr-x}/{scenario-slug}.{png|json|txt}`

### Tool 選択
- IdP UI (PR-B), web (PR-C): **playwright-cli** (Chromium、WebAuthn virtual authenticator 利用可)
- backend (PR-D): **Bash + curl**
- auth-helper (PR-A): 単体テストのみ (agent QA 不要)
- ADR / progress (PR-E): markdown / yaml validation + roadmap CLI

---

## Execution Strategy

### PR Dependency Graph
```
PR-A (auth-helper) ────┐
                       ├─→ PR-C (web OAuth)   ──┐
PR-B (IdP UI) ─────────┤                        ├─→ PR-E (ADR + retro + progress)
                       └─→ PR-D (backend RS)  ──┘
                                                       (任意) PR-F (playwright e2e CI)
```

### Wave 構成
- **Wave 1 (parallel)**: PR-A (auth-helper) + PR-B (IdP UI)
- **Wave 2 (parallel, after Wave 1)**: PR-C (web) + PR-D (backend)
- **Wave 3 (after Wave 2)**: PR-E (ADR + retro + progress)
- **Wave 4 (任意)**: PR-F (playwright e2e CI 化)
- **Wave FINAL**: 4-way 並列 review (oracle / code quality / real QA / scope fidelity)

### Critical Path
PR-A → PR-C (or PR-D) → PR-E
推定: 各 PR 0.5〜2 営業日、合計 3〜5 営業日 (待機含まず)

### Agent Dispatch Summary
- PR-A: `quick` (純粋ライブラリ、機械的)
- PR-B: `visual-engineering` + `playwright-cli` skill (Remix UI + WebAuthn 検証)
- PR-C: `unspecified-high` + `playwright-cli` skill (OAuth フロー + BFF)
- PR-D: `unspecified-high` (Hono + jose, テスト充実)
- PR-E: `writing` (ADR / retrospective / progress.yaml 編集)
- PR-F (任意): `unspecified-high` + `playwright-cli` skill

---

## TODOs

- [x] **A1. auth-helper 既存スタブの完成 (tsconfig + src/index.ts + package.json exports)** (PR-A / Wave 1)

  **What to do**:
  - **既存 stub** `js/package/auth-helper/package.json` を完成形に更新:
    - 現状は `{ "name": "auth-helper", "private": true, "type": "module" }` のみ
    - `exports: { ".": "./src/index.ts" }` 追加
    - `devDependencies: { "@totto2727/fp": "workspace:*", "@types/node": "catalog:types" }` 追加
  - `js/package/auth-helper/tsconfig.json` を新規作成 (`effect-hono/tsconfig.json` と同形)
  - `js/package/auth-helper/src/index.ts` を新規作成 (barrel)
  - **vite.config.ts は作成しない** — `effect-hono` / `remix-helper` 同様、純粋 TS ライブラリで build / test task は不要 (root の `vp test` が `test.dir: 'js/'` で自動スキャン)
  - **pnpm-workspace.yaml は確認のみ** (`js/package/*` カバー済の想定、要なら追加)

  **Must NOT do**:
  - `vite.config.ts` を作成 (`effect-hono` / `remix-helper` パターンに統一 — 余計な build task を作らない)
  - `node_modules` に余計な依存を追加 (Effect, hono, jose 等は使わない — 純粋ライブラリ)
  - パッケージ名変更 (`auth-helper` を維持。`@totto2727/auth-helper` への変更は別 cycle)

  **Recommended Agent Profile**:
  - **Category**: `quick` — 既存 stub の完成、機械的
  - **Skills**: なし

  **Parallelization**:
  - **Can Run In Parallel**: YES — Wave 1 で A1+A2+B1+B2+B3 が並列可能
  - **Blocks**: A2 (実装), PR-C, PR-D
  - **Blocked By**: なし

  **References**:
  - **現状の `js/package/auth-helper/package.json`** (main) — stub を完成形へ拡張する起点
  - `feat/ms-02-pr7-auth-helper:js/package/auth-helper/package.json` — pr7 が想定した完成形
  - `js/package/effect-hono/package.json` — sibling パッケージ完成形 (`effect: catalog:effect` 等の dev/peer 構成、exports 形式)
  - `js/package/effect-hono/tsconfig.json` — そのまま参考
  - `js/package/remix-helper/package.json` + `tsconfig.json` — もう一つの sibling

  **WHY Each Reference Matters**:
  - auth-helper は main で stub のため "新規作成" ではなく "stub を完成形に拡張" のメンタルモデル必須
  - effect-hono / remix-helper は ms-01 Phase 2 で確立された "純粋 TS shared library" パターン (vite.config.ts なし、scripts なし、source-only) — auth-helper も完全同形にする
  - pr7 の package.json は構造の参考になるが vite.config.ts 等は不要なため独自判断

  **Acceptance Criteria**:
  - [ ] `js/package/auth-helper/package.json` に `exports`, `devDependencies` が記載
  - [ ] `js/package/auth-helper/tsconfig.json` 存在
  - [ ] `js/package/auth-helper/src/index.ts` 存在
  - [ ] `js/package/auth-helper/vite.config.ts` は **存在しない** (パターン統一)
  - [ ] `pnpm install` で workspace symlink が解決 (feed-platform-web / feed-platform-backend / identity-provider が auth-helper を解決可能)

  **QA Scenarios**:
  ```
  Scenario: Package が workspace から認識される
    Tool: Bash
    Preconditions: A1 完了
    Steps:
      1. pnpm list --filter auth-helper を実行
      2. node -e "import('auth-helper').then(m => console.log(Object.keys(m)))" でロード可能性確認 (空 export でも throw しないこと)
    Expected Result: パッケージが workspace package として list 表示、import 時 throw 無し
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-a/a1-workspace.txt
  ```

  **Commit**: YES (groups with A2)
  - Message: `feat(auth-helper): complete shared workspace package stub (package.json + tsconfig + barrel)`
  - Files: `js/package/auth-helper/{package.json,tsconfig.json,src/index.ts}`
  - Pre-commit: `vp check` (build task は無い)

- [x] **A2. auth-helper 実装 (constants + cookie-translator + jwt-payload)** (PR-A / Wave 1)

  **What to do**:
  - `src/constants.ts`: `FEED_SESSION_COOKIE = 'feed-session'`, `OAUTH_BASE_PATH = '/api/v1/auth/oauth'`, 必要なら `OAUTH_CLIENT_ID = 'feed-platform-web'`, `OAUTH_SCOPES = ['openid','profile','email'] as const`
  - `src/jwt-payload.ts`: `AppJWTPayload` 型 (sub, email, iat, exp 等。pr6/pr7 既存ファイル流用)
  - `src/cookie-translator.ts`: `extractBearerFromCookie(name, cookieHeader)` (pr7 既存) — ゼロランタイム依存
  - `src/cookie-translator.test.ts`: pr7 の 6 ケース流用 + ケース追加 (大文字小文字、空白、複数 cookie パース)
  - `src/index.ts`: 全 export を barrel

  **Must NOT do**:
  - Effect / hono に依存 (ゼロランタイム依存維持)
  - 文字列リテラルの重複定義 (constants 一元化)
  - `as any` の使用

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: なし (純粋 TS)

  **Parallelization**:
  - **Can Run In Parallel**: YES (A1 と同 Task でもよいが分割推奨)
  - **Blocks**: PR-C, PR-D
  - **Blocked By**: A1

  **References**:
  - `feat/ms-02-pr7-auth-helper:js/package/auth-helper/src/constants.ts` — そのまま流用
  - `feat/ms-02-pr7-auth-helper:js/package/auth-helper/src/cookie-translator.ts` — そのまま流用
  - `feat/ms-02-pr7-auth-helper:js/package/auth-helper/src/cookie-translator.test.ts` — そのまま流用
  - `feat/ms-02-pr7-auth-helper:js/package/auth-helper/src/jwt-payload.ts` — そのまま流用

  **WHY Each Reference Matters**:
  - pr7 ブランチに実装が完成している。pr5/pr6 が "inline" で剥がしたのは consumer 側の都合。auth-helper 自体の実装は健全 → 完全流用が最速最安全。

  **Acceptance Criteria**:
  - [ ] `vp test run js/package/auth-helper` PASS (6+ ケース)
  - [ ] `vp check` PASS (lint / format / type)
  - [ ] `node -e "import('auth-helper').then(m => console.log(m.FEED_SESSION_COOKIE, m.OAUTH_BASE_PATH))"` で値出力

  **QA Scenarios**:
  ```
  Scenario: cookie-translator が valid cookie を Bearer 文字列に変換
    Tool: Bash
    Preconditions: A2 完了
    Steps:
      1. node -e "const {extractBearerFromCookie} = await import('auth-helper'); console.log(extractBearerFromCookie('feed-session', 'feed-session=abc.def.ghi'))"
    Expected Result: stdout が "Bearer abc.def.ghi"
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-a/a2-translator-ok.txt

  Scenario: cookie 不在で null
    Tool: Bash
    Preconditions: 同上
    Steps:
      1. node -e "const {extractBearerFromCookie} = await import('auth-helper'); console.log(extractBearerFromCookie('feed-session', undefined))"
    Expected Result: stdout が "null"
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-a/a2-translator-null.txt
  ```

  **Commit**: YES (groups with A1)
  - Message: `feat(auth-helper): introduce shared workspace package for auth types, constants, and pure helpers`
  - Files: `js/package/auth-helper/src/*.ts`, `pnpm-lock.yaml` (sync if needed)
  - Pre-commit: `vp check && vp test --filter auth-helper`
  - **PR-A 提出可能ポイント**

- [ ] **B1. IdP UI ページ復元 (login / check-email / login-passkey / register-passkey / account)** (PR-B / Wave 1)

  **What to do**:
  - 新ブランチ `feat/ms-02-pr-idp-ui` を main から切る
  - `feat/ms-02-pr5-web-oauth-v2` commit `510eda87` を cherry-pick (ただし feed-platform-web 関連変更が混ざる場合は手動で IdP 側のみ抽出 — `git checkout 510eda87 -- js/app/identity-provider/`)
  - 配置ファイル:
    - `app/ui/login.tsx` (Magic Link email 入力、client-side fetch)
    - `app/ui/check-email.tsx` (`?email=` query param 表示)
    - `app/ui/login-passkey.tsx` (`navigator.credentials.get()`)
    - `app/ui/register-passkey.tsx` (`navigator.credentials.create()`)
    - `app/ui/account.tsx` (profile + logout button)
    - `app/ui/document.tsx` (lang='ja' に修正)
    - `app/routes.ts`: `FrameName` を `'login' | 'check-email' | 'register-passkey' | 'account'` に拡張
  - `app/app.tsx` で UI route を mount (Remix v3 の慣習に従う)
  - 既存テスト (greeting / health) が壊れていないか確認

  **Must NOT do**:
  - web-platform / backend 側のファイル変更 (PR-C / PR-D の領域)
  - WebAuthn ロジックを app/ui に書きすぎない (将来 `feature/auth-ui/` に分離可能な構造を意識)
  - 直接 HTML を return せず Remix v3 の component pattern に従う

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering` — Remix UI 実装
  - **Skills**: `remix` — Remix v3 の routes / loader / action / Document pattern

  **Parallelization**:
  - **Can Run In Parallel**: YES (with A1, A2, B2, B3)
  - **Blocks**: B4 (e2e 検証)
  - **Blocked By**: なし (main から開始)

  **References**:
  - `feat/ms-02-pr5-web-oauth-v2:js/app/identity-provider/app/ui/login.tsx` — 流用元
  - `feat/ms-02-pr5-web-oauth-v2:js/app/identity-provider/app/ui/check-email.tsx`
  - `feat/ms-02-pr5-web-oauth-v2:js/app/identity-provider/app/ui/login-passkey.tsx`
  - `feat/ms-02-pr5-web-oauth-v2:js/app/identity-provider/app/ui/register-passkey.tsx`
  - `feat/ms-02-pr5-web-oauth-v2:js/app/identity-provider/app/ui/account.tsx`
  - `feat/ms-02-pr5-web-oauth-v2:js/app/identity-provider/app/routes.ts` — FrameName union 拡張パターン
  - `js/app/hono-remix-v3-cloudflare-example/app/ui/todo.client.tsx` — Remix v3 client component の他例
  - 公式: https://remix.run/docs (Remix v3)

  **WHY Each Reference Matters**:
  - pr5 branch の commit `510eda87` に 5 ページ全てが既に実装済 → そのまま cherry-pick が最速
  - hono-remix-v3-cloudflare-example は社内 Remix v3 規範例

  **Acceptance Criteria**:
  - [ ] `vp test run js/app/identity-provider` PASS (既存テスト維持)
  - [ ] `vp check` PASS
  - [ ] `vp run --filter identity-provider build` PASS
  - [ ] dev server 起動時 (`vp run --filter identity-provider dev`) `/login` / `/login/check-email` / `/login/passkey` / `/register/passkey` / `/account` が 200 を返す

  **QA Scenarios**:
  ```
  Scenario: 全 UI ページが 200 で応答
    Tool: Bash (curl) + 事前 dev server 起動
    Preconditions: identity-provider dev server が localhost:8787 で稼働
    Steps:
      1. for path in /login /login/check-email /login/passkey /register/passkey /account; do curl -sw "$path %{http_code}\n" -o /dev/null http://localhost:8787$path; done
    Expected Result: 全 path で 200 (account のみ未認証時に 302/401 でも可、要件次第)
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-b/b1-pages-200.txt

  Scenario: Magic Link UI が submit を受け付ける (playwright-cli)
    Tool: playwright-cli (skill: playwright-cli)
    Preconditions: dev server 稼働
    Steps:
      1. ブラウザで http://localhost:8787/login を開く
      2. input[type=email] に "test@example.com" を入力
      3. button[type=submit] をクリック
      4. URL が /login/check-email?email=test%40example.com にリダイレクト
      5. ページに "test@example.com" が表示
    Expected Result: 全ステップ pass
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-b/b1-magic-link-submit.png
  ```

  **Commit**: YES (PR-B 単独 commit)
  - Message: `feat(identity-provider): add Remix v3 login, check-email, passkey, and account UI pages`
  - Files: `js/app/identity-provider/app/ui/*.tsx`, `js/app/identity-provider/app/routes.ts`, `js/app/identity-provider/app/app.tsx`
  - Pre-commit: `vp check && vp test --filter identity-provider && vp run --filter identity-provider build`

- [ ] **B2. OAuth consent UI 新規追加 (`/oauth/consent`)** (PR-B / Wave 1)

  **What to do**:
  - `app/ui/oauth-consent.tsx` を新規作成:
    - GET `/oauth/consent?client_id=...&scope=...&redirect_uri=...&state=...` で表示
    - client_id / scope / requested redirect_uri を表示
    - "Allow" / "Deny" ボタン → POST で better-auth の consent endpoint へ
  - `app/routes.ts`: `FrameName` に `'oauth-consent'` を追加
  - better-auth.ts の `consentPage: '/oauth/consent'` 設定と整合

  **Must NOT do**:
  - trusted client (`feed-platform-web`) でも consent を強制しない (better-auth が自動 skip するため UI は trusted 外でのみ表示)
  - scope をハードコードせず URL query から読む

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: `remix`

  **Parallelization**:
  - **Can Run In Parallel**: YES (with A1, A2, B1, B3)
  - **Blocks**: B4
  - **Blocked By**: なし

  **References**:
  - `js/app/identity-provider/app/feature/auth/better-auth.ts` (main) — `consentPage: '/oauth/consent'` で参照されている
  - better-auth docs: https://www.better-auth.com/docs/plugins/oauth-provider (consent page 仕様)
  - pr5 branch にも `oauth-consent.tsx` は **存在しない** ことを確認済 → 完全新規

  **WHY Each Reference Matters**:
  - better-auth の OAuth provider 設定が consent UI を参照しているため、trusted 外 client を追加するときに必須
  - 既存ブランチに参考実装が無い → ドキュメントで仕様確認必須

  **Acceptance Criteria**:
  - [ ] `/oauth/consent` が 200 を返す (パラメータなし呼び出しでもエラーページとして 200 で正常応答すること、404 にならない)
  - [ ] `/oauth/consent?client_id=unknown&scope=openid&redirect_uri=http://example.com&state=xyz` が consent ページを表示
  - [ ] "Allow" ボタンクリックで better-auth の consent confirm endpoint に POST → redirect_uri にリダイレクト
  - [ ] **trusted client (`feed-platform-web`) は better-auth が自動 skip するが、URL 直叩きでも到達可能であることを別途確認** (`curl -sw '%{http_code}' http://localhost:8787/oauth/consent` が 200)

  **QA Scenarios**:
  ```
  Scenario: Consent UI が必要パラメータを表示
    Tool: playwright-cli
    Preconditions: dev server 稼働 + DB に未 trusted な OAuth client 1 件 seed
    Steps:
      1. ブラウザで /oauth/consent?client_id=<test-client>&scope=openid+profile&redirect_uri=http://localhost:3000/cb&state=abc を開く
      2. ページに client_id, scope 一覧, redirect_uri が表示されることをアサート
      3. button[name="action"][value="allow"] をクリック
      4. URL が redirect_uri にリダイレクト + ?code=... が付与
    Expected Result: 全ステップ pass
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-b/b2-consent-flow.png
  ```

  **Commit**: YES (groups with B1)
  - Message: `feat(identity-provider): add OAuth consent UI`
  - Files: `js/app/identity-provider/app/ui/oauth-consent.tsx`, `js/app/identity-provider/app/routes.ts`
  - Pre-commit: `vp check && vp test --filter identity-provider`

- [ ] **B3. dev 用 oauth_application seed** (PR-B / Wave 1)

  **What to do**:
  - **事前検証 (必須)**: seed SQL を書く前に `db/schema.hcl` および `app/feature/db/generated.ts` (kysely-codegen 出力) で `oauth_application` テーブルの実際のカラム名 / 型を確認すること。better-auth の `oauthClient: { modelName: 'oauth_application' }` 設定により modelName は固定だが、フィールド名は better-auth のデフォルト + plugin の組み合わせで決まる
  - `js/app/identity-provider/db/seeds/oauth_application.sql` を作成 (dev 用):
    - `feed-platform-web` クライアントを `oauth_application` テーブルに insert
    - 必要フィールド (better-auth が要求する全て — 例: `id`, `clientId`, `clientSecret`, `redirectURLs`, `name`, `trusted`, `createdAt` 等): 実際のスキーマに合わせる
    - client_id: `feed-platform-web` (better-auth.ts の `cachedTrustedClients` と一致)
    - client_secret: dev 用固定値 (例: `dev-secret-do-not-use-in-prod`)
    - redirect_uris: `http://localhost:8788/auth/callback`
    - trusted: true
  - `Justfile` (db タスク) に `seed-oauth` ターゲット追加 (`atlas migrate apply` 等の既存タスクに続けて呼べる形)

  **Must NOT do**:
  - 本番秘密値を seed に書く (dev 専用、`.gitignore` で本番値は除外)
  - 既存 atlas migration を破壊
  - **`db/generated.ts` で確認せずスキーマを推測** (テーブル / カラム名は better-auth + plugin が決定 — 推測は破綻のもと)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — DB seed + Atlas/Kysely 知識
  - **Skills**: なし

  **Parallelization**:
  - **Can Run In Parallel**: YES (with A1, A2, B1, B2)
  - **Blocks**: B4 (OAuth フロー検証)
  - **Blocked By**: なし

  **References**:
  - `js/app/identity-provider/db/schema.hcl` — **schema source of truth** (atlas-to-kysely + atlas migrate の両方の起点)
  - `js/app/identity-provider/app/feature/db/generated.ts` — kysely-codegen 出力 (テーブル / カラム名の確定形式)
  - `js/app/identity-provider/atlas.hcl`
  - `js/app/identity-provider/db/migrations/20260518171739_init.sql` — 確定済 migration (`oauth_application` テーブル定義の参考)
  - `js/app/identity-provider/Justfile` — db タスク既存パターン (commit `4ce33fc5` で追加)
  - `js/app/identity-provider/app/feature/auth/better-auth.ts` (main) — `oauthClient: { modelName: 'oauth_application' }`, `cachedTrustedClients: new Set(['feed-platform-web'])` 設定確認
  - better-auth oauthProvider docs: https://www.better-auth.com/docs/plugins/oauth-provider

  **WHY Each Reference Matters**:
  - oauth_application テーブルに row が無いと OAuth authorize endpoint が "unknown_client" を返す → dev で動作確認するために必須
  - Justfile に既存 db タスクパターンあり → 同形で seed タスク追加

  **Acceptance Criteria**:
  - [ ] dev DB に `feed-platform-web` row が存在 (`SELECT * FROM oauth_application WHERE client_id='feed-platform-web'`)
  - [ ] `just seed-oauth` (または該当コマンド) で冪等に seed 実行可能

  **QA Scenarios**:
  ```
  Scenario: OAuth client seed が DB に存在
    Tool: Bash + sqlite3 (or libsql CLI)
    Preconditions: dev DB 起動済
    Steps:
      1. just seed-oauth を実行
      2. sqlite3 <dev-db> "SELECT client_id, trusted FROM oauth_application WHERE client_id='feed-platform-web'"
    Expected Result: stdout に "feed-platform-web|1" (or 同等)
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-b/b3-seed.txt

  Scenario: authorize endpoint が unknown_client を返さない
    Tool: Bash + curl
    Preconditions: B3 seed 完了 + dev server 稼働
    Steps:
      1. curl -sw "%{http_code}" "http://localhost:8787/api/v1/auth/oauth2/authorize?response_type=code&client_id=feed-platform-web&redirect_uri=http://localhost:8788/auth/callback&code_challenge=abc&code_challenge_method=S256&state=xyz&scope=openid"
    Expected Result: 200 or 302 (login redirect)、決して 400 "unknown_client" を返さない
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-b/b3-authorize.txt
  ```

  **Commit**: YES (groups with B1, B2)
  - Message: `feat(identity-provider): add dev seed for feed-platform-web OAuth client`
  - Files: `js/app/identity-provider/db/seeds/oauth_application.sql`, `js/app/identity-provider/Justfile`
  - Pre-commit: `vp check`

- [ ] **B4. IdP UI E2E 検証 (playwright-cli)** (PR-B / Wave 1)

  **What to do**:
  - playwright-cli を用いて IdP UI 全フロー検証 (B1+B2+B3 完了後):
    - Magic Link 発行 → mock sender からリンク取得 → セッション確立
    - Passkey 登録 → 仮想 authenticator で credentials.create
    - Passkey ログイン → 仮想 authenticator で credentials.get
    - OAuth authorize → consent (trusted のため skip) → callback redirect (consumer 未実装でも redirect 自体は検証可能)
    - Logout → /account が unauthed リダイレクト
  - 各シナリオの evidence (screenshot + console log) を保存
  - 失敗時は console.log / network エラーログを capture

  **Must NOT do**:
  - 本番 IdP / 実メール送信 (mock sender 経由のみ)
  - 自動テストを test/ にコミット (このタスクは agent QA のみ。CI 化は PR-F で別途)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: `playwright-cli`

  **Parallelization**:
  - **Can Run In Parallel**: NO — B1+B2+B3 完了後に直列実行
  - **Blocks**: PR-B merge gate
  - **Blocked By**: B1, B2, B3

  **References**:
  - `js/app/identity-provider/app/feature/email/mock.ts` — Magic Link テキスト取得方法
  - Chromium DevTools Protocol: WebAuthn.addVirtualAuthenticator (playwright-cli 経由でも可)
  - playwright-cli skill docs

  **WHY Each Reference Matters**:
  - mock email sender が Magic Link をどう吐くかでテスト戦略変わる (console / log / API endpoint)
  - WebAuthn 仮想 authenticator なしでは Passkey 検証不可

  **Acceptance Criteria**:
  - [ ] 5 シナリオ全 PASS
  - [ ] evidence ファイル全 5 件 (`.sisyphus/evidence/feed-platform-ms-02/pr-b/b4-*.png`) 存在

  **QA Scenarios**:
  ```
  Scenario: Magic Link 全通し
    Tool: playwright-cli
    Preconditions: IdP dev server + mock sender 稼働
    Steps:
      1. /login に遷移
      2. email "alice@example.com" 入力 → submit
      3. /login/check-email にリダイレクト
      4. mock sender のログから magic link URL を取得 (`docker logs` or file tail)
      5. 取得した URL にブラウザで遷移
      6. /account にリダイレクト + email "alice@example.com" 表示
    Expected Result: 全ステップ pass
    Failure Indicators: /login/check-email にリダイレクトしない / mock log に link が出ない / /account が 401 を返す
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-b/b4-magic-link-full.png

  Scenario: Passkey 登録 + ログイン (WebAuthn virtual authenticator)
    Tool: playwright-cli
    Preconditions: Magic Link で先にログイン済み (Passkey 登録は authed user 前提)
    Steps:
      1. CDP で WebAuthn virtual authenticator 追加
      2. /register/passkey に遷移
      3. "Register passkey" ボタンクリック → credentials.create 完了 → 成功メッセージ
      4. /account から logout
      5. /login/passkey に遷移、email 入力 → "Sign in with passkey" → credentials.get 完了
      6. /account に遷移、email 表示
    Expected Result: 全ステップ pass
    Failure Indicators: credentials.create で例外 / signin で 401
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-b/b4-passkey-full.png

  Scenario: Logout
    Tool: playwright-cli
    Preconditions: ログイン済
    Steps:
      1. /account で logout ボタンクリック
      2. /login にリダイレクト (またはホーム)
      3. /account に再アクセス → unauth リダイレクト
    Expected Result: pass
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-b/b4-logout.png
  ```

  **Commit**: NO (検証のみ。コードは B1/B2/B3 でコミット済)
  - **PR-B 提出可能ポイント** (B1〜B4 完了時)

- [x] **C1. web OAuth クライアント実装 (oauth-client + callback + constants)** (PR-C / Wave 2)

  **What to do**:
  - **前提確認**: `js/app/feed-platform-web/package.json` 既に `auth-helper: "workspace:*"` を devDependencies に含む (main 上で確認済) → 新たな dep 追加は不要、import だけ書く
  - 新ブランチ `feat/ms-02-pr-web-oauth` を main (PR-A merge 済) から切る
  - `js/app/feed-platform-web/app/feature/auth/oauth-client.ts` を作成 (pr5 流用):
    - `generateVerifier()` / `generateChallenge(verifier)` / `generateState()` — PKCE primitives (crypto.subtle)
    - `buildAuthorizeUrl(params)` — IdP の authorize endpoint URL 組み立て
  - `js/app/feed-platform-web/app/feature/auth/callback.ts` を作成 (pr5 流用):
    - `/auth/callback?code=...&state=...` 処理
    - state 検証 (Cookie / KV から取得した期待値と一致)
    - `POST /api/v1/auth/oauth2/token` で code → access_token + id_token 交換
    - id_token を `feed-session` HttpOnly Cookie に格納
  - `js/app/feed-platform-web/app/feature/auth/constants.ts`:
    - `auth-helper` からの re-export のみ (`export { FEED_SESSION_COOKIE, OAUTH_BASE_PATH } from 'auth-helper'`)
    - **インライン定義禁止** (pr5 の `cddd9e53 inline FEED_SESSION_COOKIE` を回帰させない)
  - 単体テスト (pr5 流用): `oauth-client.test.ts`, `callback.test.ts`

  **Must NOT do**:
  - 定数のインライン化 (auth-helper 必須 import)
  - id_token を localStorage / sessionStorage に保存 (HttpOnly Cookie のみ)
  - PKCE verifier を Cookie に平文で保存 (signed / encrypted KV 等)
  - `as any` の使用

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — OAuth + crypto + Cookie の組み合わせ
  - **Skills**: なし (純粋実装)

  **Parallelization**:
  - **Can Run In Parallel**: YES (with C2, D1, D2)
  - **Blocks**: C3 (e2e 検証)
  - **Blocked By**: A1, A2 (auth-helper merge 済)

  **References**:
  - `feat/ms-02-pr5-web-oauth-v2:js/app/feed-platform-web/app/feature/auth/oauth-client.ts` — 流用元 (PKCE primitives 全部)
  - `feat/ms-02-pr5-web-oauth-v2:js/app/feed-platform-web/app/feature/auth/callback.ts`
  - `feat/ms-02-pr5-web-oauth-v2:js/app/feed-platform-web/app/feature/auth/oauth-client.test.ts`
  - `feat/ms-02-pr5-web-oauth-v2:js/app/feed-platform-web/app/feature/auth/callback.test.ts`
  - `js/app/identity-provider/app/feature/auth/better-auth.ts` (main) — IdP 側の OAuth endpoint URL を確認
  - 公式: https://datatracker.ietf.org/doc/html/rfc7636 (PKCE)
  - 公式: https://www.better-auth.com/docs/plugins/oauth-provider

  **WHY Each Reference Matters**:
  - pr5 既存実装は better-auth の OAuth2 endpoint (`/api/v1/auth/oauth2/authorize`, `/token`) に合わせた URL 構築済 → 流用最速
  - PKCE RFC は code_challenge_method=S256 の base64url 仕様確認のため
  - constants の auth-helper import 化が C1 の鍵 (pr5 の "inline" 回帰阻止)

  **Acceptance Criteria**:
  - [ ] `vp test run js/app/feed-platform-web` PASS (oauth-client.test.ts + callback.test.ts)
  - [ ] `vp check` PASS
  - [ ] `vp run --filter feed-platform-web build` PASS
  - [ ] `import` 文 grep で `FEED_SESSION_COOKIE` の inline 定義が無い (`grep -r "FEED_SESSION_COOKIE = " js/app/feed-platform-web/` → 0 件)

  **QA Scenarios**:
  ```
  Scenario: PKCE primitives が RFC 7636 準拠の base64url を返す
    Tool: Bash
    Preconditions: C1 完了
    Steps:
      1. vp test --filter feed-platform-web oauth-client.test.ts を実行
    Expected Result: 全 ケース PASS、verifier 長さ 43-128 chars、challenge SHA-256 base64url
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-c/c1-pkce-tests.txt

  Scenario: auth-helper からの import が成立
    Tool: Bash
    Preconditions: C1 完了
    Steps:
      1. grep -nE "from ['\"]auth-helper['\"]" js/app/feed-platform-web/app/feature/auth/constants.ts
    Expected Result: マッチ 1 件以上 (constants.ts は auth-helper を import)
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-c/c1-helper-import.txt
  ```

  **Commit**: YES (groups with C2)
  - Message: `feat(feed-platform-web): add OAuth 2.1 PKCE client and callback handler`
  - Files: `js/app/feed-platform-web/app/feature/auth/{oauth-client,callback,constants}.ts(.test.ts)`
  - Pre-commit: `vp check && vp test --filter feed-platform-web`

- [x] **C2. web auth middleware + BFF api/client** (PR-C / Wave 2)

  **What to do**:
  - `js/app/feed-platform-web/app/feature/auth/middleware.ts` (pr5 流用):
    - `feed-session` Cookie から JWT を取得
    - `createRemoteJWKSet(${IDP_BASE_URL}/api/v1/auth/jwks)` で公開鍵取得
    - jose `jwtVerify` で署名 + claims 検証
    - 検証成功で `c.set('user', AuthUser)` 失敗で 401
  - `js/app/feed-platform-web/app/feature/api/client.ts` (pr5 流用):
    - Cookie-to-Bearer BFF: request の `Cookie: feed-session=...` から `auth-helper.extractBearerFromCookie` で Bearer 文字列を抽出し `Authorization` ヘッダで backend に転送
    - `fetch` ラッパとして `api/client.ts` を実装
  - 単体テスト: middleware.test.ts (jose mock), client.test.ts
  - 環境変数: `IDP_BASE_URL` を `wrangler.jsonc` に追加 (`vars` または `secret`)

  **Must NOT do**:
  - jose を auth-helper にバンドルしない (web 専用依存)
  - `process.env.IDP_BASE_URL ?? 'http://localhost:8787'` のように本番デフォルト無しのフォールバックを書かない (環境必須化)
  - inline cookie name (auth-helper 経由)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: なし

  **Parallelization**:
  - **Can Run In Parallel**: YES (with C1)
  - **Blocks**: C3
  - **Blocked By**: A1, A2

  **References**:
  - `feat/ms-02-pr5-web-oauth-v2:js/app/feed-platform-web/app/feature/auth/middleware.ts` — 流用元
  - `feat/ms-02-pr5-web-oauth-v2:js/app/feed-platform-web/app/feature/auth/middleware.test.ts`
  - `feat/ms-02-pr5-web-oauth-v2:js/app/feed-platform-web/app/feature/api/client.ts` — BFF パターン
  - `feat/ms-02-pr5-web-oauth-v2:js/app/feed-platform-web/app/feature/api/client.test.ts`
  - jose: https://github.com/panva/jose/blob/main/docs/key/jwks.md (createRemoteJWKSet)
  - `js/package/auth-helper/src/cookie-translator.ts` (PR-A) — Cookie-to-Bearer ロジック

  **WHY Each Reference Matters**:
  - pr5 middleware 実装が完全 → そのまま流用 + auth-helper import 修正のみ
  - BFF パターンは auth-helper の `extractBearerFromCookie` を直接呼べば 1 行で済む

  **Acceptance Criteria**:
  - [ ] `vp test --filter feed-platform-web` PASS (middleware + api/client)
  - [ ] Cookie 無しリクエストで middleware が 401 を返す (unit test)
  - [ ] Cookie 付きリクエストで `c.var.user` がセットされる (unit test)
  - [ ] api/client が `Authorization: Bearer ...` を付与 (unit test)

  **QA Scenarios**:
  ```
  Scenario: middleware が unauth で 401 を返す
    Tool: Bash + curl (wrangler dev で web 起動後)
    Preconditions: C1+C2 完了、web dev server 稼働
    Steps:
      1. curl -sw "\n%{http_code}\n" http://localhost:8788/api/protected (任意の保護 endpoint)
    Expected Result: 401 + JSON error body
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-c/c2-unauth-401.txt

  Scenario: 有効 JWT Cookie で middleware が user をセット
    Tool: Bash + curl
    Preconditions: 有効 JWT を IdP から取得済み
    Steps:
      1. curl -H "Cookie: feed-session=<jwt>" http://localhost:8788/api/protected
    Expected Result: 200 + user JSON
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-c/c2-authed-200.txt
  ```

  **Commit**: YES (groups with C1)
  - Message: `feat(feed-platform-web): add auth middleware and Cookie-to-Bearer BFF api client`
  - Files: `js/app/feed-platform-web/app/feature/{auth/middleware.ts(.test.ts),api/client.ts(.test.ts)}`, `js/app/feed-platform-web/wrangler.jsonc` (env vars)
  - Pre-commit: `vp check && vp test --filter feed-platform-web`

- [ ] **C3. cross-app login E2E 検証 (playwright-cli)** (PR-C / Wave 2)

  **What to do**:
  - playwright-cli で **web → IdP → web** 全通し検証
  - 前提: PR-A merge 済 + PR-B merge 済 + C1+C2 完了
  - Evidence: cross-app フローのスクリーンショット連鎖

  **Must NOT do**:
  - mock IdP を使わない (実 IdP dev server 経由)
  - state 検証を skip しない

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: `playwright-cli`

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocks**: PR-C merge gate
  - **Blocked By**: C1, C2 + (PR-B merged)

  **References**:
  - PR-B の B4 evidence (IdP UI 単体動作確認済)
  - `feat/ms-02-pr5-web-oauth-v2` のコミット msg `feat(feed-platform-web): add OAuth 2.1 PKCE client, auth middleware, and Cookie-to-Bearer BFF`

  **WHY Each Reference Matters**:
  - PR-B 完了が前提 (IdP UI 無しでは cross-app 全通し不可)
  - pr5 が当初想定していた cross-app フローを再現

  **Acceptance Criteria**:
  - [ ] cross-app magic link login が成立
  - [ ] cross-app passkey login が成立 (PR-B B4 で virtual authenticator がセットアップ済)
  - [ ] /protected route が web 側で gating される

  **QA Scenarios**:
  ```
  Scenario: web → IdP magic link → web cross-app login
    Tool: playwright-cli
    Preconditions: 全 dev server 稼働 (IdP:8787, web:8788)
    Steps:
      1. http://localhost:8788/ にアクセス
      2. "Login" ボタンクリック → IdP /login にリダイレクト (URL 確認)
      3. email "alice@example.com" 入力 → submit
      4. mock sender ログから magic link 取得
      5. magic link にアクセス → IdP で session 確立
      6. (trusted client なので consent skip) → /auth/callback?code=... に redirect
      7. web 側で code → token 交換 → feed-session Cookie がセット
      8. /protected にアクセス → 200 + user 情報表示
    Expected Result: 全ステップ pass
    Failure Indicators: callback で 400 / Cookie がセットされない / /protected で 401
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-c/c3-cross-app-magic.png

  Scenario: web → IdP passkey → web cross-app login
    Tool: playwright-cli (WebAuthn virtual authenticator)
    Preconditions: PR-B B4 で passkey 登録済の email
    Steps:
      1. web /login → IdP /login → "Use passkey" → IdP /login/passkey
      2. email 入力 → credentials.get
      3. callback → web に redirect + Cookie セット
      4. /protected で 200
    Expected Result: pass
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-c/c3-cross-app-passkey.png
  ```

  **Commit**: NO (検証のみ)
  - **PR-C 提出可能ポイント** (C1〜C3 完了時、PR-A + PR-B が main にあること前提)

- [x] **D1. backend JWT verification service** (PR-D / Wave 2)

  **What to do**:
  - **前提確認**: `js/app/feed-platform-backend/package.json` 既に `auth-helper: "workspace:*"` を devDependencies に含む (main 上で確認済) → 新たな dep 追加は不要、import だけ書く
  - 新ブランチ `feat/ms-02-pr-backend-rs` を main (PR-A merge 済) から切る
  - `js/app/feed-platform-backend/src/feature/auth/jwt-payload.ts` (pr6 流用):
    - **auth-helper から `AppJWTPayload` を import + re-export** のみ (pr6 の inline は禁止)
  - `js/app/feed-platform-backend/src/feature/auth/jwt.ts` (pr6 流用):
    - Effect Service として `JwtService` を定義
    - `verify(token: string): Effect.Effect<AppJWTPayload, JwtError>`
    - `createRemoteJWKSet(${IDP_BASE_URL}/api/v1/auth/jwks)` で公開鍵取得
    - jose `jwtVerify(token, jwks, { issuer, audience })` で検証
    - `liveLayer` を export
  - 単体テスト `jwt.test.ts` (pr6 流用): jose mock で valid/invalid/expired 各ケース

  **Must NOT do**:
  - `AppJWTPayload` を inline 定義 (auth-helper 経由)
  - jose のバージョンを web 側と分離 (catalog で統一)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: なし (Effect + jose の組み合わせ)

  **Parallelization**:
  - **Can Run In Parallel**: YES (with C1, C2, D2)
  - **Blocks**: D2 (middleware が JwtService を使う)
  - **Blocked By**: A1, A2

  **References**:
  - `feat/ms-02-pr6-backend-rs-v2:js/app/feed-platform-backend/src/feature/auth/jwt-payload.ts`
  - `feat/ms-02-pr6-backend-rs-v2:js/app/feed-platform-backend/src/feature/auth/jwt.ts`
  - `feat/ms-02-pr6-backend-rs-v2:js/app/feed-platform-backend/src/feature/auth/jwt.test.ts`
  - `js/package/auth-helper/src/jwt-payload.ts` (PR-A) — `AppJWTPayload` 型 source of truth
  - jose: https://github.com/panva/jose/blob/main/docs/jwt/verify/functions/jwtVerify.md

  **WHY Each Reference Matters**:
  - pr6 ブランチの jwt.ts は Effect Service + jose 統合済 → 流用最速
  - auth-helper の AppJWTPayload を使うことで web/backend で型が一致 (将来の claim 追加にも追随)

  **Acceptance Criteria**:
  - [ ] `vp test run js/app/feed-platform-backend` PASS (jwt.test.ts)
  - [ ] `vp check` PASS
  - [ ] `vp run --filter feed-platform-backend build` PASS
  - [ ] `grep -nE "interface AppJWTPayload|type AppJWTPayload" js/app/feed-platform-backend/` → 0 件 (inline 無し、auth-helper のみ)

  **QA Scenarios**:
  ```
  Scenario: jose mock で valid JWT を検証
    Tool: Bash
    Preconditions: D1 完了
    Steps:
      1. vp test --filter feed-platform-backend jwt.test.ts を実行
    Expected Result: 全ケース PASS (valid / expired / wrong issuer / invalid signature)
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-d/d1-jwt-tests.txt
  ```

  **Commit**: YES (groups with D2)
  - Message: `feat(feed-platform-backend): add JWT verification service using auth-helper types`
  - Files: `js/app/feed-platform-backend/src/feature/auth/{jwt-payload,jwt,jwt.test}.ts`
  - Pre-commit: `vp check && vp test --filter feed-platform-backend`

- [x] **D2. backend auth middleware + 保護 /api/v1/me** (PR-D / Wave 2)

  **What to do**:
  - `js/app/feed-platform-backend/src/feature/auth/middleware.ts` (pr6 流用):
    - `Authorization: Bearer ...` ヘッダから token 抽出
    - `JwtService.verify(token)` で検証 → 成功で `c.set('user', payload)` 失敗で 401 + `WWW-Authenticate: Bearer error="invalid_token"`
  - `js/app/feed-platform-backend/src/feature/auth/middleware.test.ts` (pr6 流用): 401 / 200 各ケース
  - 保護 endpoint `/api/v1/me` を `src/worker/bff/worker.ts` (またはルーティング層) に追加:
    - middleware 適用後 `c.var.user` を JSON で返す

  **Must NOT do**:
  - Cookie からの認証 (backend は Bearer のみ — Cookie 解析は web 側 BFF の責務)
  - エラーメッセージで JWT 内容を leak

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: なし

  **Parallelization**:
  - **Can Run In Parallel**: NO (D1 後直列)
  - **Blocks**: D3
  - **Blocked By**: D1

  **References**:
  - `feat/ms-02-pr6-backend-rs-v2:js/app/feed-platform-backend/src/feature/auth/middleware.ts`
  - `feat/ms-02-pr6-backend-rs-v2:js/app/feed-platform-backend/src/feature/auth/middleware.test.ts`
  - `feat/ms-02-pr6-backend-rs-v2:js/app/feed-platform-backend/src/worker/bff/worker.ts` — /api/v1/me 設置箇所
  - RFC 6750 Bearer Token Usage

  **WHY Each Reference Matters**:
  - pr6 middleware は WWW-Authenticate ヘッダの仕様準拠済 (`Bearer error="invalid_token"`) → そのまま流用
  - `/api/v1/me` の設置箇所は worker/bff/worker.ts (既存 worker 構造に合わせる)

  **Acceptance Criteria**:
  - [ ] `vp test --filter feed-platform-backend` PASS (middleware.test.ts)
  - [ ] `vp run --filter feed-platform-backend build` PASS

  **QA Scenarios**:
  ```
  Scenario: Unauth リクエストが 401 + WWW-Authenticate を返す
    Tool: Bash + curl (wrangler dev で backend 起動済)
    Preconditions: D2 完了、backend dev server 稼働
    Steps:
      1. curl -sw "\nstatus=%{http_code}\n" -D - http://localhost:8789/api/v1/me 2>&1
    Expected Result: status=401, ヘッダに 'WWW-Authenticate: Bearer error="invalid_token"' を含む
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-d/d2-unauth.txt

  Scenario: 有効 Bearer で 200 + user JSON
    Tool: Bash + curl
    Preconditions: IdP から取得した有効 JWT を $TOKEN にセット
    Steps:
      1. curl -H "Authorization: Bearer $TOKEN" http://localhost:8789/api/v1/me
    Expected Result: 200, JSON body に { sub, email } を含む
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-d/d2-authed.txt

  Scenario: 改竄トークンで 401
    Tool: Bash + curl
    Preconditions: 有効 JWT の末尾を 1 文字書き換えた値 $BAD_TOKEN
    Steps:
      1. curl -sw "\n%{http_code}\n" -H "Authorization: Bearer $BAD_TOKEN" http://localhost:8789/api/v1/me
    Expected Result: 401
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-d/d2-tampered.txt
  ```

  **Commit**: YES (groups with D1)
  - Message: `feat(feed-platform-backend): add auth middleware and protected /api/v1/me endpoint`
  - Files: `js/app/feed-platform-backend/src/feature/auth/middleware.ts(.test.ts)`, `js/app/feed-platform-backend/src/worker/bff/worker.ts`
  - Pre-commit: `vp check && vp test --filter feed-platform-backend`

- [ ] **D3. backend E2E 検証 (curl ベース)** (PR-D / Wave 2)

  **What to do**:
  - D1+D2 完了後、curl で実 backend dev server に対する 3 シナリオを実行
  - 上記 D2 QA Scenarios と同等。evidence 取得目的の独立タスク

  **Must NOT do**:
  - 自動テストにこのシナリオを追加 (CI 化は PR-F)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: なし

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocks**: PR-D merge gate
  - **Blocked By**: D1, D2

  **References**:
  - D2 QA Scenarios (上記)

  **Acceptance Criteria**:
  - [ ] 3 シナリオ全 PASS、evidence 3 ファイル存在

  **QA Scenarios**: D2 と同じ (再掲不要)

  **Commit**: NO (検証のみ)
  - **PR-D 提出可能ポイント** (D1〜D3 完了時)

- [ ] **E1. ADR 3 本ドラフト + confirm** (PR-E / Wave 3)

  **What to do**:
  - `docs/adr/<date>-feed-platform-auth-provider.md`: Better Auth を OAuth プロバイダとして採用した理由 / 検討した代替案 (Auth0, Keycloak, Clerk) / トレードオフ
  - `docs/adr/<date>-feed-platform-cross-app-session-strategy.md`: OAuth 2.1 Authorization Code + PKCE + JWT (ES256) Bearer Cookie パターン / なぜ shared secret や OIDC discovery を選ばないか / Cookie path / SameSite / HttpOnly / Secure
  - `docs/adr/<date>-feed-platform-magic-link-strategy.md`: Magic Link expiry (default 10 分) / 配信経路 (Cloudflare Email Workers vs HTTP API) / トークン再利用防止 (single-use)
  - `feat/ms-02-pr8-adr-progress-v2` ブランチの ADR を確認 → 流用 / 上書き判断
  - status: confirmed (実装完了済のため)

  **Must NOT do**:
  - 実装と異なる ADR を書く (実装が source of truth)
  - 検討した代替案を省略

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: `docs-structure` — ADR の格納場所と README/AGENTS の分離規則

  **Parallelization**:
  - **Can Run In Parallel**: YES (with E2)
  - **Blocks**: E3 (progress.yaml は ADR 確定後)
  - **Blocked By**: PR-A, PR-B, PR-C, PR-D マージ済

  **References**:
  - `feat/ms-02-pr8-adr-progress-v2` 差分 (要 git diff main..pr8 で内容確認)
  - `docs/adr/` 既存 ADR (フォーマット参考)
  - `plugins/dev-workflow/skills/share-artifacts/references/adr.md` (ADR 書き方ガイド)
  - `plugins/dev-workflow/skills/share-artifacts/templates/adr.md` (テンプレ)

  **WHY Each Reference Matters**:
  - dev-workflow plugin に ADR フォーマットが標準化されている (status: proposed/accepted/confirmed/rejected/superseded 等)
  - pr8 ブランチに drafted ADR があるはず (未確認 → executor が PR-E 着手時に確認 + 統合)

  **Acceptance Criteria**:
  - [ ] 3 ADR が `docs/adr/` 配下に存在、各 status: confirmed
  - [ ] それぞれ Context / Decision / Consequences が記述済
  - [ ] `vp check` PASS (markdown lint)

  **QA Scenarios**:
  ```
  Scenario: ADR が 3 本存在
    Tool: Bash
    Preconditions: E1 完了
    Steps:
      1. ls docs/adr/ | grep -E "feed-platform-(auth-provider|cross-app-session|magic-link)"
    Expected Result: 3 ファイル
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-e/e1-adr-list.txt
  ```

  **Commit**: YES (groups with E2, E3)
  - Message: `docs(adr): add feed-platform ms-02 auth ADRs (provider / cross-app session / magic link)`

- [ ] **E2. retrospective 起票** (PR-E / Wave 3)

  **What to do**:
  - `docs/retrospective/feed-platform-ms-02-auth-passkey-magiclink.md` を作成
  - 内容:
    - 目標達成度 (定性 / 定量)
    - 学び: pr5 conflation の反省、auth-helper "abandoned" 反省、`/oauth/consent` 欠落の反省
    - 後続マイルストーン (ms-03 RBAC + Organization) への引き継ぎ事項
  - dev-workflow plugin の retrospective テンプレに準拠

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: なし

  **Parallelization**:
  - **Can Run In Parallel**: YES (with E1)
  - **Blocks**: E3
  - **Blocked By**: PR-A〜D マージ済

  **References**:
  - `docs/retrospective/feed-platform-ms-01-workspace-foundation.md` — 先行 retrospective の形
  - `plugins/dev-workflow/skills/share-artifacts/references/retrospective.md`

  **Acceptance Criteria**:
  - [ ] retrospective ファイル存在
  - [ ] 「学び」セクションに具体的 commit hash 引用

  **QA Scenarios**:
  ```
  Scenario: retrospective ファイル存在
    Tool: Bash
    Steps:
      1. test -f docs/retrospective/feed-platform-ms-02-auth-passkey-magiclink.md && echo OK || echo MISSING
    Expected Result: stdout "OK"
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-e/e2-retro.txt
  ```

  **Commit**: YES (groups with E1, E3)
  - Message: `docs(retrospective): add feed-platform ms-02 retrospective`

- [x] **E3. progress.yaml + milestone .md status 更新** (PR-E / Wave 3)

  **What to do**:
  - roadmap CLI で:
    - `node js/app/roadmap/dist/bin.mjs milestone set status feed-platform ms-02-auth-passkey-magiclink completed`
    - `node js/app/roadmap/dist/bin.mjs milestone set note feed-platform ms-02-auth-passkey-magiclink "<retrospective 要約>"`
  - `docs/roadmap/feed-platform/milestones/ms-02-auth-passkey-magiclink.md` の `Status: planned` → `completed` 手動更新
  - milestone .md の "関連 dev-workflow サイクル" 表に実際のサイクル ID を記入 (該当する場合)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: なし

  **Parallelization**:
  - **Can Run In Parallel**: NO (E1+E2 後)
  - **Blocks**: PR-E merge gate
  - **Blocked By**: E1, E2

  **References**:
  - `docs/roadmap/feed-platform/progress.yaml`
  - `docs/roadmap/feed-platform/milestones/ms-02-auth-passkey-magiclink.md`
  - `js/app/roadmap/dist/bin.mjs` — roadmap CLI

  **Acceptance Criteria**:
  - [ ] `roadmap status feed-platform` で ms-02 = completed
  - [ ] milestone .md の Status 行が completed

  **QA Scenarios**:
  ```
  Scenario: progress.yaml 反映
    Tool: Bash
    Steps:
      1. node js/app/roadmap/dist/bin.mjs status feed-platform
    Expected Result: stdout に "ms-02-auth-passkey-magiclink (completed)" を含む
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-e/e3-status.txt
  ```

  **Commit**: YES (groups with E1, E2)
  - Message: `chore(roadmap): mark ms-02-auth-passkey-magiclink as completed`
  - Files: `docs/adr/*.md`, `docs/retrospective/feed-platform-ms-02-auth-passkey-magiclink.md`, `docs/roadmap/feed-platform/progress.yaml`, `docs/roadmap/feed-platform/milestones/ms-02-auth-passkey-magiclink.md`
  - Pre-commit: `vp check`
  - **PR-E 提出可能ポイント** (E1〜E3 完了時)

- [ ] **F1 (任意). Cross-app E2E CI 化 (playwright)** (PR-F / Wave 4)

  **What to do**:
  - `tests/e2e/feed-platform-auth.spec.ts` (場所はモノレポ規則に従う) を作成
  - PR-B B4 / PR-C C3 で実施した playwright-cli シナリオを Playwright スクリプトに変換
  - WebAuthn virtual authenticator セットアップ
  - mock email sender 経由で magic link 取得を E2E 化
  - GitHub Actions CI に組み込み

  **Must NOT do**:
  - 既存 vitest unit テストを E2E に変換 (層は分ける)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: `playwright-cli`

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocks**: なし (任意)
  - **Blocked By**: PR-A〜E マージ済

  **References**:
  - PR-B / PR-C の playwright-cli evidence
  - `.playwright/` 既存設定があれば
  - Playwright docs: https://playwright.dev/docs/intro

  **Acceptance Criteria**:
  - [ ] CI で playwright e2e green
  - [ ] テスト dir 構造が monorepo 規則準拠

  **QA Scenarios**:
  ```
  Scenario: CI で e2e PASS
    Tool: Bash
    Steps:
      1. pnpm dlx playwright test (or `vp test run js/<e2e-package-path>`)
    Expected Result: 全 spec pass
    Evidence: .sisyphus/evidence/feed-platform-ms-02/pr-f/f1-ci.txt
  ```

  **Commit**: YES (PR-F 単独)
  - Message: `test(feed-platform): add cross-app e2e auth flow with playwright`
  - Pre-commit: e2e 自身が PASS

---

## Final Verification Wave (after all PRs merged)

- [x] **F1. Plan Compliance Audit** — `oracle`
  Read each PR diff vs this plan. For each "Must Have": grep main for evidence (auth-helper imports in consumers, `/oauth/consent.tsx` exists, ADR files exist). For each "Must NOT Have": grep for inline constants / `as any` / `console.log`. Evidence: `.sisyphus/evidence/feed-platform-ms-02/F1-compliance.md`
  Output: `Must Have [N/N] | Must NOT Have [N/N] | VERDICT: APPROVE/REJECT`

- [x] **F2. Code Quality Review** — `unspecified-high`
  `vp check` + `vp test` + `vp run -r build` on main. Lint diff for AI slop / over-comment / unused imports. Evidence: `.sisyphus/evidence/feed-platform-ms-02/F2-quality.txt`
  Output: `Build/Lint/Test status + clean file count + VERDICT`

- [ ] **F3. Real Manual QA** — `unspecified-high` + `playwright-cli` skill
  全 PR の QA シナリオを統合実行: cross-app login (magic link + passkey) → backend protected endpoint → logout。Evidence: `.sisyphus/evidence/feed-platform-ms-02/F3-e2e/`
  Output: `Scenarios [N/N pass] + VERDICT`

- [x] **F4. Scope Fidelity Check** — `deep`
  各 PR diff vs plan "What to do" 1:1 比較。未承認の変更 / スコープ漏れを検出。Evidence: `.sisyphus/evidence/feed-platform-ms-02/F4-scope.md`
  Output: `PRs [N/N compliant] + VERDICT`

→ 4 並列終了後、user に提示 → 明示的 okay を得てから ms-02 → completed

---

## Commit Strategy

- PR ごとに 1 ブランチ、conventional commits
- PR-A: `feat(auth-helper): introduce shared workspace package for auth types, constants, and pure helpers`
- PR-B: `feat(identity-provider): add login/check-email/passkey/account/oauth-consent UI pages`
- PR-C: `feat(feed-platform-web): add OAuth 2.1 PKCE client, auth middleware, and Cookie-to-Bearer BFF`
- PR-D: `feat(feed-platform-backend): add JWT verification service, auth middleware, and protected /api/v1/me endpoint`
- PR-E: `docs(feed-platform): add auth ADRs, ms-02 retrospective, and update progress.yaml`
- PR-F: `test(feed-platform): add cross-app e2e auth flow with playwright`

各 PR の pre-commit: `vp check && vp test run js/<path-to-changed-package>` (または `vp test` 全体)

---

## Success Criteria

### Verification Commands
```bash
# 全体
vp run -r ci                      # check + test + build all packages PASS

# 各 PR ごと
vp test --filter auth-helper            # PR-A
vp test --filter identity-provider      # PR-B
vp test --filter feed-platform-web      # PR-C
vp test --filter feed-platform-backend  # PR-D

# Roadmap CLI
node js/app/roadmap/dist/bin.mjs status feed-platform   # ms-02 status: completed

# Cross-app E2E (PR-F が無くても playwright-cli で手動検証)
curl -sw '%{http_code}\n' http://localhost:8788/api/v1/me   # 401
# (有効 JWT 取得後)
curl -H "Authorization: Bearer <token>" http://localhost:8788/api/v1/me   # 200
```

### Final Checklist
- [ ] PR-A〜PR-E 全マージ
- [ ] `vp run -r ci` PASS
- [ ] cross-app login (magic link + passkey) 全通し
- [ ] `roadmap status feed-platform` で ms-02 = completed
- [ ] ADR 3 本確定 + retrospective 確定
- [ ] auth-helper を consumer が import している (インライン無し)
- [ ] `js/app/identity-provider/app/ui/oauth-consent.tsx` 存在
- [ ] secrets が commit されていない
