# Intent Spec: feed-platform Workspace Foundation

- **Identifier:** feed-platform-ms-01-workspace-foundation
- **Author:** totto2727 (Main 起草)
- **Created at:** 2026-05-04T12:55:38Z
- **Last updated:** 2026-05-05T02:15:00Z
- **Roadmap:** `feed-platform` / milestone `ms-01-workspace-foundation`

## Background

`feed-platform` ロードマップ (`docs/roadmap/feed-platform/roadmap.md`) の起点マイルストーン (ms-01 Workspace Foundation) として起動した dev-workflow サイクル。後続 9 マイルストーン (ms-02 認証認可 / ms-03 RBAC + Organization / ms-04 期間限定共有 / ms-05 永続化 / ms-06 入力プラグイン / ms-07 出力プラグイン / ms-08 定期実行 / ms-09 AI 要約 / ms-10 統合検証) はすべて本サイクルで整備された土台 (採用ワークスペース + 3 プロジェクト構成 + 実行環境 + 認証認可アーキテクチャ大枠) を前提として進む。

ロードマップ Intent の戦略層制約 (サーバレスアーキテクチャ原則 / マイクロサービス境界としてのプラグイン分割 / イベントソーシング + CQRS / コードレベル契約のみのプラグイン拡張) を、プロジェクト構成・命名・実行環境のレベルで具現化することが本サイクルの責務。実装の中身 (認証フロー / イベントストア / アダプタ実装等) は後続マイルストーンに完全委譲する。

## Purpose

本サイクル完了時点で以下を成立させる:

1. `js/` ワークスペース上に **3 プロジェクト** (`feed-platform-backend` / `feed-platform-web` / `identity-provider`) の最小雛形が配置され、`vp check` / `vp test` が 3 プロジェクトすべてで通過する
2. **バックエンド** (`feed-platform-backend`) は **Cloudflare Workers + wrangler 直接実行**構成で、entry point ごとに独立デプロイ可能な構造 (= `worker.ts` + `wrangler.jsonc` のペアが entry ごとに存在) を実証
3. **Web フロント** (`feed-platform-web`) と **認証基幹サーバ** (`identity-provider`) は **Hono + Remix v3 + Cloudflare Workers** パターン (`js/app/hono-remix-v3-cloudflare-example` 最新構成踏襲) で成立
4. **2 本の ADR** (ADR-01 プロジェクト構造 + 実行環境 = Roadmap mode、ADR-02 認証認可アーキテクチャ + `identity-provider` 汎用化 = General mode) が起票され、後続マイルストーン (および将来の他システム) が参照可能な不変記録となる

## Scope

確定済み事項 (Q2 〜 Q3、Step 1 対話で会話駆動・漸増的に確定):

### 確定済み

- **採用ワークスペース: `js/`** (Q2 確定 — 2026-05-04)
  - 根拠: ロードマップ Intent 明示推奨 (`docs/roadmap/feed-platform/roadmap.md:65`)、既存スキル群 (`effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp` / `remix`) との整合性最大、CQRS / イベントソーシング / サーバレス BFF の参照実装が monorepo 内に既存
  - 詳細根拠は ms-01 で起票する ADR の最初の 1 本として記録予定
- **プロジェクト分割: バックエンド + Web フロントエンド の 2 プロジェクト構成** (Q2.5 確定 — 2026-05-04 改訂)
  - 旧案 (単一 `js/app/feed-platform/`) は破棄。バックエンドと Web フロントエンドで技術選定が大きく異なる見込みのため、最初から 2 プロジェクトに分離する
  - **バックエンド**: 入力アダプタ / 出力アダプタ / 永続化 / 定期実行 / AI 要約等のサーバーサイド全般を含む (詳細は後続マイルストーン責務)
  - **Web フロントエンド**: 現状想定は Hono + Remix v3 ベースの Web UI。「Web」を限定子として明示し、将来 mobile / desktop クライアントが出力プラグインとして追加される際に、それらは別プロジェクトとして起こせる構造を保つ
  - パッケージ分割の更なる細分化 (BFF 別 / Worker 別 / 共通 library 切り出し) は引き続き YAGNI 方針で、後続マイルストーンの設計で必要になり次第実施
- **BFF (Backend-for-Frontend) の配置: バックエンド側に主配置 + Web フロントエンド側に SSR + 軽量 BFF** (Q2.6 確定 — 2026-05-05)
  - **バックエンド側 BFF**: DB / イベントストア / 業務ロジックへのアクセスを伴う API は全てバックエンド側に配置 (= design-hint L9 の "Resource-Oriented BFF" の物理配置先)。後述「認証認可アーキテクチャ」のリソースサーバーに相当する
  - **Web フロントエンド側**: サーバーサイドレンダリング (SSR) + バックエンドへのアクセスを必要としない軽量な表示用 API のみ。重い処理 / DB 直接アクセスは全てバックエンド側 BFF に転送
  - 根拠: DB / イベントストアの所有がバックエンド側に閉じるため、データアクセスを伴う API はバックエンド側で完結する方が信頼境界 / レイテンシ / 認可判定を単純化できる
- **認証認可アーキテクチャ大枠** (Q2.7 確定 — 2026-05-05、抽象アーキテクチャレベルのみ。具体技術選定は `docs/roadmap/feed-platform/design-hint.md` の「認証認可アーキテクチャの素案」参照)
  - 4 種の構成要素:
    1. **クライアント** — Web フロントエンド (将来 mobile / CLI 等を含む) が OAuth 2.1 クライアントとして JWT を取得・保持
    2. **基幹サーバー (Authorization Server)** — 認証 (パスワード / Passkey / Magic Link 等) + 組織・メンバー・ロール管理 + OAuth 2.1 認可フロー + JWT 発行 + JWKS 公開を担う。**認証認可情報の唯一のソース・オブ・トゥルース** (DB を所有)
    3. **リソースサーバー** — バックエンド側 BFF / API 群がこれに相当。JWT 検証 (JWKS キャッシュ) + 認可判定 (in-memory ポリシーエンジン) + ビジネスロジック実行を担う。**認証認可 DB を共有しない**
    4. **共有 authz レイヤー** — ロール定義 + ポリシー (ロール × 操作の許可マッピング) を Git 管理コードとして配布。リソースサーバー群に import される
  - 認証認可フロー: クライアント → (OAuth 2.1 + PKCE) → 基幹サーバー → JWT 発行 → クライアント → (Bearer JWT) → リソースサーバー → ローカル JWT 検証 + ローカル認可判定 → ビジネスロジック実行。**通常リクエスト経路に基幹サーバー問い合わせは発生しない** (アクセスはログイン時 / トークン更新時のみ)
  - **JWT 送信方法 (Cookie / Authorization ヘッダーの使い分け)** (Q2.7-extension 確定 — 2026-05-05):
    - **ブラウザ ↔ Web フロントエンドサーバー (SSR + 軽量 BFF) 間: Cookie に JWT を保存して送信**。これにより一般的なリンク遷移 (GET) や form submission でも認証情報を自然に伝搬可能 (= 通常の Web ナビゲーションが認証下で機能する)
    - **Web フロントエンドサーバー → リソースサーバー (バックエンド) 間: Authorization: Bearer ヘッダー**。Web フロントエンドサーバーは Cookie から JWT を抽出し、Bearer ヘッダーに付け替えてリソースサーバーを呼ぶ (= BFF パターンの Cookie ↔ Bearer 翻訳責務)
    - **その他クライアント (将来追加される mobile / CLI / ブラウザ JS から直接リソースサーバー呼び出し等) → リソースサーバー間: Authorization: Bearer ヘッダー**
    - **リソースサーバーは Cookie を一切受理せず、Authorization ヘッダーのみで認証**する設計 (= 信頼境界を Authorization ヘッダー由来の JWT に統一)
    - Cookie の `httponly` 属性採用判断は **要検討事項として保留** (水際対策としての効果 vs クライアントサイド JS からの操作可否のトレードオフ)
  - **拡張パスを不変インターフェースで吸収**: 認可判定インターフェース (`can(jwt, resource, action)` 相当) を不変に保ったまま、内部実装を段階的に進化可能とする構造を採用 (Phase 1: 静的ポリシー → ... → Phase N: 独立 PDP 等)。具体段階定義は design-hint 参照
- **基幹サーバー (Authorization Server) の配置: 独立した 3 番目のプロジェクト** (Q2.8 確定 — 2026-05-05)
  - feed-platform 関連プロジェクト (バックエンド / Web フロントエンド) とは別の独立プロジェクトとして配置
  - 根拠: 今後他システムでも利用する可能性を視野に入れる。基幹サーバーは feed-platform 専用ではなく、**汎用的な認証認可サーバー**として設計する
  - 名前空間 / 命名は `feed-platform-*` に閉じない汎用名を採用 (具体命名は後続ターンで確定)
  - 実装作業は feed-platform ロードマップ ms-02 (Passkey + Magic Link) / ms-03 (RBAC + Organization) / ms-04 (期間限定共有) が担うが、feed-platform 固有要件に閉じない汎用性を維持した設計とする
- **バックエンドプロジェクトの内部構造: 1 プロジェクト + 複数サーバレス関数** (Q2.9 確定 — 2026-05-05)
  - バックエンドはソースコード単位では **1 プロジェクト (1 `package.json` / 1 ワークスペース)** として構成
  - 内部に **複数のサーバレス関数 (BFF / Worker / Cron 等) を配置し、それぞれが個別にデプロイ可能**となる構造を採用
  - 根拠: ロードマップ Intent の「マイクロサービス境界としてのプラグイン分割」原則 (`docs/roadmap/feed-platform/roadmap.md:65`) と「サーバレスアーキテクチャ原則」(`roadmap.md:64`) の両立。ソース管理単位を 1 つに保ちつつ、デプロイ単位は責務 / スケーリング特性ごとに独立させる
  - 同一原則を Web フロントエンドプロジェクトにも適用可能 (SSR + 軽量 BFF の関数を必要に応じて分割) だが、Web フロントは現状単一サーバー (SSR + loader / action 一体) として開始し、必要時に分割する
  - 関数分割の具体粒度 (BFF をリソース単位に分けるか / Worker をアダプタ単位に分けるか等) は後続マイルストーン設計で確定
  - ビルド / packaging の具体方針 (個別デプロイ可能にするツール選定: Vite+ / wrangler / esbuild マルチエントリ等) は ms-01 雛形整備の段階で素地のみ決定 (本格的な分割は後続)
- **ms-01 のスコープ: 3 プロジェクト全部の最小雛形を ms-01 で立ち上げ** (Q2.10 確定 — 2026-05-05、案 α' 採用 / Q2.12 確定で具体内容を改訂)
  - **3 プロジェクト共通**: `package.json` + `tsconfig.json` + Ultracite (Oxlint + Oxfmt) 設定 + 既存規約準拠の `vite.config.ts` 内 Vite+ task 定義 (`check` / `fix` / `test` / `build` / `setup` 等) + smoke test 1 件 + `effect-layer` / `effect-runtime` パターンの最小 Service 例 1 件 + `vp check` / `vp test` 通過
  - **バックエンド (`feed-platform-backend`) 固有**: **Cloudflare Workers + wrangler 直接実行パターン**。各 entry point に `worker.ts` + `wrangler.jsonc` のペアを配置 (例: `src/bff/worker.ts` + `src/bff/wrangler.jsonc`、`src/worker-input/worker.ts` + `src/worker-input/wrangler.jsonc`)。各 entry は Hello World 相当 (`/health` 200 OK 等) のみ。Q2.9「個別デプロイ可能」を Cloudflare Workers + wrangler 構成で実現
  - **Web フロント (`feed-platform-web`) 固有**: **Cloudflare Workers + Hono + Remix v3 パターン (`js/app/hono-remix-v3-cloudflare-example` の最新構成踏襲)**。`app/` ディレクトリ構造 + `app/entry.worker.ts` + `app/routes.ts` + 単一 `wrangler.jsonc` + `vite.config.ts`。Hello World 1 ページ + `loader` 経由の JSON 例 1 件
  - **認証基幹サーバ (`identity-provider`) 固有**: **Web フロントと同じ Cloudflare Workers + Hono + Remix v3 パターン + DB 設定**。ログインページ等の UI を持つ性格上、純粋なバックエンドではなく Web フロント構成 + DB binding 等の追加設定として扱う。ms-01 では Hello World 相当 (簡易 "Hello, IdP" ページ等) のみ。**OAuth 2.1 / 認証フレームワーク (Better Auth 等) の導入は ms-02 の責務として残し、ms-01 では含めない**
  - **テスト**: vp (Vitest)、**設定はひとまず 1 個**で開始 (root レベル or 1 プロジェクト設定をベース、後続で必要に応じて分離)
  - **個別デプロイの自動検証は ms-01 では行わない (手動デプロイ運用)**: ロードマップ Intent 非スコープ「CI / 本番デプロイ自動化」(`roadmap.md:47`) と整合。ms-01 では「ビルド成果物が独立に生成される / `wrangler.jsonc` が entry ごとに整っている」までを観測対象とし、CI / 自動デプロイは後続マイルストーン or 別ロードマップで扱う
  - 根拠: ロードマップ ms-01 マイルストーン定義書の責務遵守 (`docs/roadmap/feed-platform/milestones/ms-01-workspace-foundation.md:20-22`) + 3 プロジェクト並列構成 + pnpm workspace の協調動作を ms-01 で検証 + 後続マイルストーンが「workspace 整備の手戻り」に遭わない保険 + Cloudflare Workers 構成の早期実証
- **ビルド / packaging 方針** (Q2.12 確定 — 2026-05-05)
  - **デプロイターゲット: Cloudflare Workers** を ms-01 で確定 (ロードマップ Intent の「サーバレス原則」を Cloudflare Workers として具現化)
  - **バックエンド**: **wrangler 直接実行**。entry point ごとに `worker.ts` + `wrangler.jsonc` のペアを配置し、`wrangler deploy` を entry ごとに実行 (= 個別デプロイ可能)
  - **Web フロント / 認証基幹サーバ**: **Vite + Remix v3 + Cloudflare Workers** (`js/app/hono-remix-v3-cloudflare-example` パターン)。`vite build` でビルド出力、`wrangler` でデプロイ
  - **テスト**: vp (Vitest)。設定は ms-01 段階では 1 個のみ (root or 単一プロジェクトベース)。プロジェクトごとの分離 / カスタマイズは需要発生時 (ms-02 以降)
  - **CI / 本番デプロイ自動化は本サイクル非スコープ** (後続マイルストーン or 別ロードマップで扱う、現状は手動)
  - **既存 monorepo の Vite+ task 規約**を全プロジェクトで踏襲: `vite.config.ts` 内 `run.tasks` で `check` / `fix` / `test` / `build` / `setup` を定義 (CLAUDE.md `Standard Tasks` 節準拠)
- **3 プロジェクトの命名** (Q2.11 確定 — 2026-05-05)
  - バックエンド: **`feed-platform-backend`** (内部に複数サーバレス関数 = BFF / Worker / Cron 等を包括)
  - Web フロントエンド: **`feed-platform-web`** (Hono + Remix v3 ベース、SSR + 軽量 BFF を含む Web 経路)
  - 認証基幹サーバ: **`identity-provider`** (= OIDC / OAuth 2.1 における Identity Provider。`feed-platform-*` 名前空間外、汎用認証基幹サーバとして他システムからの再利用を視野)
  - 配置: 全て `js/app/<name>/` 直下
- **認証 (authn) と認可 (authz) のコード命名上の区別原則** (Q2.11-extension 確定 — 2026-05-05)
  - **認証 (authn) 担当** = `identity-provider` (ID / クレデンシャル検証 + JWT 発行 + 組織 / メンバー / ロールの SoT 保持)
  - **認可 (authz) 担当** = リソースサーバー内の認可判定 + 共有 authz パッケージ (将来の独立 PDP に分離可)
  - 命名上の対比: `identity-provider` (= identity / authn) ↔ 共有 authz パッケージ / 将来の `authz-server` (= 認可)
  - 共有 authz パッケージの将来配置 (`js/package/authz/` 汎用 vs `js/package/feed-platform-authz/` feed-platform 専用) は **ms-03 (RBAC) で確定**。ms-01 の Intent Spec では default を仮置きせず、design-hint の素案メモに留める
  - 根拠: 認可は Phase 4 (design-hint H 拡張パス) で独立サービス化される可能性があり、その時点で `authz-server` 等の独立プロジェクト命名が必要となる。`identity-provider` を認証専任の命名とすることで、将来の認可分離後も命名衝突せずに整合する
- **横断 ADR の起票範囲: 2 ADR 案を採用** (Q3 確定 — 2026-05-05)
  - **ADR-01 (Roadmap mode)** — `docs/roadmap/feed-platform/adr/2026-05-05-project-structure-and-runtime.md`
    - 内容: ワークスペース選定 (`js/`) / 3 プロジェクト構成 / BFF 配置 / バックエンド内部分割 (1 プロジェクト + 複数サーバレス関数) / プロジェクト命名 / Cloudflare Workers + wrangler + Vite + Remix v3 実行環境
    - 含む確定事項: Q2, Q2.5, Q2.6, Q2.9, Q2.10, Q2.11 (命名部分), Q2.12
    - 影響範囲: feed-platform ロードマップ内のすべての配下サイクル
  - **ADR-02 (General mode)** — `docs/adr/2026-05-05-identity-provider-and-authn-authz-architecture.md`
    - 内容: 認証認可アーキテクチャ 4 構成要素 / JWT 送信方法 (Cookie + Bearer の使い分け) / 拡張パス Phase 1-5 (`can()` インターフェース不変原則) / `identity-provider` の汎用化方針 (他システム再利用視野) / authn/authz 区別原則
    - 含む確定事項: Q2.7, Q2.7-extension, Q2.8, Q2.11-extension
    - 影響範囲: feed-platform 内 + 本リポジトリで認証認可を要する将来の他システム
  - **起票タイミング**: Step 6 (Implementation) で雛形作成と並行して `share-adr` スキル経由で起票する (Step 1 ではメタ確定のみ)

### 未確定 (後続マイルストーン委譲または ms-01 内で詰める残論点)

- バックエンド内のサーバレス関数分割粒度 (ms-01 では「分割可能な構造」の素地のみ整備、具体は後続マイルストーン設計)
- Cookie の `httponly` 採用判断 (ms-02 委譲)

## Out of scope

本サイクルでは扱わず、後続マイルストーン (or 別サイクル / 別ロードマップ) に委譲する事項:

- **認証認可の実装ロジック** (Better Auth / jose / Casbin 等の導入と実装、Passkey / Magic Link 実装、RBAC 実装、Organization 切替実装、期間限定共有実装) — ms-02 / ms-03 / ms-04 責務
- **イベントストア / プロジェクション / Aggregate 実装** — ms-05 責務
- **入力プラグイン / 出力プラグインの契約 interface 定義と参照実装** (RSS / HTML 解析 / X リスト / Slack / Web UI 配信等) — ms-06 / ms-07 責務
- **定期実行基盤** (Cron / Pub/Sub による分割実行) — ms-08 責務
- **AI 要約機能** — ms-09 責務
- **統合検証 (E2E シナリオ)** — ms-10 責務
- **CI / 本番デプロイ自動化** — 別ロードマップで扱う (ロードマップ Intent 非スコープ `roadmap.md:47`)。本サイクルでは手動デプロイのみ
- **Cookie の `httponly` 採用判断** — ms-02 で確定
- **共有 authz パッケージの配置先と内部実装** — ms-03 で確定
- **Cloudflare Workers 以外のサーバレス実行環境への対応** (AWS Lambda / Vercel Edge / 他) — ロードマップ非スコープ
- **バックエンド内サーバレス関数分割の具体粒度** (BFF をリソース単位にどう分けるか / Worker をアダプタ単位にどう分けるか) — 後続マイルストーン設計責務、ms-01 では「分割可能な構造」の素地のみ
- **`feed-platform-backend` 以外のプロジェクトでの内部関数分割** — Web フロント / 認証基幹サーバは ms-01 では単一サーバーとして開始

## Success criteria

各 SC は観測可能な形で記述。verification 手段を併記。

- **SC-1**: `js/app/feed-platform-backend/` / `js/app/feed-platform-web/` / `js/app/identity-provider/` の 3 ディレクトリが存在し、各々に `package.json` が配置されている
  - 観測: `ls js/app/<name>/package.json` が成功
- **SC-2**: 3 プロジェクトすべてで `vp run check` (`js/app/<name>/` から実行 or `vp run --filter <package>` 経由) が exit 0 で終了 (Lint / Format / 型チェック通過)
  - 観測: 各プロジェクトで `vp run check; echo $?` が `0`
- **SC-3**: 3 プロジェクトすべてで `vp run test` が exit 0 で終了し、各プロジェクトに smoke test が 1 件以上 PASS する
  - 観測: 各プロジェクトで `vp run test; echo $?` が `0` かつ Vitest 出力で `passed` 件数 ≥ 1
- **SC-4**: `vp run -r build` (or 同等のワークスペース全体ビルド) が成功し、3 プロジェクトすべてのビルド成果物が出力される
  - 観測: `vp run -r build; echo $?` が `0` かつ各プロジェクト所定の出力ディレクトリにファイルが生成されている
- **SC-5**: `js/app/feed-platform-backend/` には entry point ごとに `worker.ts` + `wrangler.jsonc` のペアが配置され、entry が **2 件以上**存在する (= Q2.9 「個別デプロイ可能」の構造的担保)
  - 観測: `find js/app/feed-platform-backend/src -name 'worker.ts'` の件数 ≥ 2 かつ各 worker.ts と同じディレクトリに `wrangler.jsonc` が存在
- **SC-6**: 各プロジェクトに `effect-layer` / `effect-runtime` パターンを使った Service 定義例が 1 件以上含まれる
  - 観測: 各プロジェクト内に `Layer` / `ServiceMap.Service` / `ManagedRuntime` のいずれかを使う TypeScript ファイルが存在
- **SC-7**: ADR-01 (`docs/roadmap/feed-platform/adr/2026-05-05-project-structure-and-runtime.md`) が起票され、Q2 / Q2.5 / Q2.6 / Q2.9 / Q2.10 / Q2.11 (命名) / Q2.12 の決定根拠が記録されている
  - 観測: ファイル存在 + ADR テンプレート (`share-adr` スキル準拠) の主要セクション (Status / Context / Decision / Consequences) を満たす
- **SC-8**: ADR-02 (`docs/adr/2026-05-05-identity-provider-and-authn-authz-architecture.md`) が起票され、Q2.7 / Q2.7-extension / Q2.8 / Q2.11-extension の決定根拠が記録されている
  - 観測: 同上
- **SC-9**: `feed-platform-web` と `identity-provider` が `js/app/hono-remix-v3-cloudflare-example` 最新構成と整合する (`app/` ディレクトリ + `app/entry.worker.ts` + `wrangler.jsonc` + `vite.config.ts`)
  - 観測: 各プロジェクトに上記 4 ファイル / ディレクトリが存在
- **SC-10**: GitHub Actions CI (root の `vp run --parallel ci`) が ms-01 の最終コミットで PASS する
  - 観測: PR の `## CI status` セクションに `success` が記録される (share-ci-monitoring 双重チェック準拠)
- **SC-11**: `roadmap-progress.yaml.milestones[ms-01-workspace-foundation]` が `status: completed` に遷移できる状態 (= Step 9 Retrospective 完了時に問題なく `completed` 化できる前提を満たす)
  - 観測: SC-1 〜 SC-10 がすべて PASS していること

## Constraints

### 技術的制約

- 採用ワークスペース: **`js/`** (Q2 確定)
- 実行環境: **Cloudflare Workers** (Q2.12 確定、ロードマップ Intent の「サーバレス原則」を具現化)
- フレームワーク: **Hono / Remix v3 / Effect / Vite+** (既存 monorepo 規約準拠)
- ビルド: バックエンド = **wrangler 直接**、Web フロント / 認証基幹サーバ = **Vite + Remix v3 (Cloudflare 適応)**
- テスト: **vp (Vitest)**。ms-01 段階では設定 1 個のみ
- パッケージ管理: **pnpm workspace + catalog** (既存規約)
- Lint / Format: **Ultracite (Oxlint + Oxfmt)** (既存規約)
- 既存規約: `CLAUDE.md` の `Standard Tasks` 節、`vp` コマンド優先 (`npx` / `bunx` 使用禁止)
- ADR は本リポジトリ内の `share-adr` スキルに準拠 (Roadmap mode = `docs/roadmap/feed-platform/adr/`、General mode = `docs/adr/`)

### 組織的制約

- 個人開発 (totto2727 単独)、Specialist は dev-workflow の subagent として並列起動
- 並行 dev-workflow サイクル数の上限: **2** (ロードマップ Intent `roadmap.md:71`)
- ms-01 は Wave 0 (起点) のため並行サイクルなし

### 規範的制約

- ロードマップ Intent の「大局的制約」セクション (`roadmap.md` セクション「大局的制約」) を継承
- 既存プロジェクト固有スキル (`effect-layer` / `effect-runtime` / `effect-hono` / `git-workflow` / `adr` / `script-rules` / `totto2727-fp` 等) のパターン優先
- 機密情報 (API キー / 個人情報 / 共有トークン等) をリポジトリに保存しない
- 本サイクルが `dev-workflow` の 9 ステップ体系および `dev-roadmap` の 4 ステップ体系に準拠
- 認証 (authn) と認可 (authz) のコード命名上の区別原則を遵守 (Q2.11-extension)

## Related links

- ロードマップ: `docs/roadmap/feed-platform/roadmap.md`
- マイルストーン: `docs/roadmap/feed-platform/milestones/ms-01-workspace-foundation.md`
- ロードマップ設計素案: `docs/roadmap/feed-platform/design-hint.md`
- ロードマップ進捗: `docs/roadmap/feed-platform/roadmap-progress.yaml`

## Open questions

Step 1 対話で残った論点は以下のみ (すべて後続マイルストーン委譲済みであり、本サイクル Step 2 以降では扱わない):

- バックエンド内のサーバレス関数分割粒度 — 後続マイルストーン (ms-05 / ms-06 / ms-08 等) 設計責務
- Cookie の `httponly` 採用判断 — ms-02 委譲
- 共有 authz パッケージの配置先 — ms-03 委譲
- design-hint の素案論点 (L1 〜 L9 + 認証認可素案 D / E / F / G / H / I / J) — 各論点の委譲先マイルストーンで扱う

なお Step 1 (Intent Clarification) 自体は本セクションに残る論点が存在しない状態 (= 後続マイルストーン委譲のみ) で完了する。
