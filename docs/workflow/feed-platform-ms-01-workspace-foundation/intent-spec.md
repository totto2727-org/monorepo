# Intent Spec: feed-platform Workspace Foundation

- **Identifier:** feed-platform-ms-01-workspace-foundation
- **Author:** totto2727 (Main 起草)
- **Created at:** 2026-05-04T12:55:38Z
- **Last updated:** 2026-05-05T02:00:00Z
- **Roadmap:** `feed-platform` / milestone `ms-01-workspace-foundation`

## Background

(Step 1 対話で確定 — TBD)

## Purpose

(Step 1 対話で確定 — TBD)

## Scope

Step 1 対話で 1 つずつ確定し追記する (会話駆動・漸増方式)。

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

### 未確定 (後続ターンで追記)

- バックエンド内のサーバレス関数分割粒度 (ms-01 では「分割可能な構造」の素地のみ整備、具体は後続マイルストーン設計)
- Cookie の `httponly` 採用判断 (ms-02 委譲済み — 水際対策としての XSS 起因 JWT 漏洩抑止効果 vs クライアントサイド JS から JWT に触れない制約のトレードオフ)
- **横断 ADR の起票範囲 (Q3)** — Q2 〜 Q2.12 確定により ADR 候補が増えたため、何を ms-01 サイクル内で起票するかを最終確定する必要

## Out of scope

(Step 1 対話で確定 — TBD)

## Success criteria

Step 1 対話で 1 つずつ確定し追記する (会話駆動・漸増方式)。観測可能な形で記述する。

- (TBD)

## Constraints

(Step 1 対話で確定 — TBD)

## Related links

- ロードマップ: `docs/roadmap/feed-platform/roadmap.md`
- マイルストーン: `docs/roadmap/feed-platform/milestones/ms-01-workspace-foundation.md`
- ロードマップ設計素案: `docs/roadmap/feed-platform/design-hint.md`
- ロードマップ進捗: `docs/roadmap/feed-platform/roadmap-progress.yaml`

## Open questions

Step 1 対話の進行に伴って追記。

- (TBD)
