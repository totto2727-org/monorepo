---
confirmed: true
scope: roadmap:feed-platform
---

# ADR: feed-platform プロジェクト構造と実行環境

- **Storage path:** docs/roadmap/feed-platform/adr/2026-05-05-project-structure-and-runtime.md

## Status

`Accepted` — 後続 9 マイルストーン (ms-02〜ms-10) はすべて本 ADR の決定事項を前提として進行する。

## Context

`feed-platform` ロードマップ (`docs/roadmap/feed-platform/roadmap.md`) は、入力アダプタ / 永続化 / 出力アダプタ / 認証認可 / 定期実行 / AI 要約 / 統合検証など 10 マイルストーンを束ねる規模であり、その起点マイルストーンとして配置された ms-01 (Workspace Foundation) は **後続マイルストーンが手戻りなく進められる土台 (採用ワークスペース + プロジェクト構成 + 実行環境)** を物理レベルで確定する責務を負う。

ロードマップ Intent (`docs/roadmap/feed-platform/roadmap.md` の「アーキテクチャ的制約」節) で以下の architectural constraints が確定している:

- **サーバレスアーキテクチャ原則**: 常駐サーバを置かず、すべての処理経路をリクエスト駆動 / イベント駆動に分解
- **マイクロサービス境界としてのプラグイン分割**: 入力 / 出力プラグインや業務責務単位で独立デプロイ可能な境界を確保
- **イベントソーシング + CQRS** の素地確保
- **コードレベル契約のみのプラグイン拡張** (= ランタイム動的ロードを採用しない)

これら制約をプロジェクト構造・命名・実行環境のレベルで構造的に保証することが ms-01 の責務であり、本 ADR が後続マイルストーンの参照する不変記録となる。

影響範囲は **feed-platform ロードマップ内のすべての配下サイクル (ms-02〜ms-10)** に閉じる。本リポジトリの他ロードマップへの影響は限定的なため、Roadmap mode (`docs/roadmap/feed-platform/adr/`) として起票した。`identity-provider` の汎用化方針 (= 他システム再利用視野) は別 ADR (ADR-02) として General mode で起票する (本 ADR と分離)。

## Decision

本 ADR は 7 つの決定事項 (D-1〜D-7) を 1 つの決定束として確定する。各決定はそれ単体では切り離せず、全体で「3 プロジェクト + Cloudflare Workers + Hono/Remix v3 + Effect」という土台を構成する。

### D-1: 採用ワークスペース = `js/`

ロードマップ全領域 (バックエンド / Web フロント / 認証基幹 / 共有 authz パッケージ) を `js/` ワークスペースに集約する。`mbt/` (MoonBit) / `go/` (Go) は採用しない。

- **根拠**: 既存 monorepo 内の関連スキル群 (`effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp` / `remix`) との整合性が最大、CQRS / イベントソーシング / サーバレス BFF の参照実装が `js/app/saas-example/` / `js/app/hono-remix-v3-cloudflare-example/` / `js/app/rss-graphql/` として既に存在し再利用可能、pnpm workspace + catalog による依存集中管理を流用可能 (intent-spec Q2)

### D-2: 3 プロジェクト構成 = `feed-platform-backend` + `feed-platform-web` + `identity-provider`

`js/app/` 直下に上記 3 プロジェクトを配置する。バックエンドと Web フロントエンドは技術選定が大きく異なる見込みのため最初から分離 (intent-spec Q2.5)、認証基幹サーバは将来の他システム再利用視野で `feed-platform-*` 名前空間外に配置 (intent-spec Q2.8、詳細は ADR-02)。

### D-3: BFF (Backend-for-Frontend) 配置 = バックエンド主 + Web フロント側に SSR + 軽量 BFF

DB / イベントストア / 業務ロジックへのアクセスを伴う API はすべてバックエンド側 (`feed-platform-backend`) に配置 (= 認証認可アーキテクチャのリソースサーバに相当)。Web フロントエンド側 (`feed-platform-web`) は SSR + バックエンドへのアクセスを必要としない軽量な表示用 API のみ。重い処理 / DB 直接アクセスはすべてバックエンド側へ転送する (intent-spec Q2.6)。

- **根拠**: DB / イベントストアの所有がバックエンド側に閉じるため、データアクセスを伴う API はバックエンド側で完結する方が信頼境界 / レイテンシ / 認可判定を単純化できる

### D-4: バックエンド内部構造 = 1 プロジェクト + 複数サーバレス関数 (個別デプロイ可)

バックエンド (`feed-platform-backend`) はソースコード単位では **1 プロジェクト (1 `package.json` / 1 ワークスペース)** として構成する一方、内部に **複数のサーバレス関数 (BFF / Worker / Cron 等) を配置し、それぞれ個別にデプロイ可能** な構造を採用する (intent-spec Q2.9)。

具体形式: `src/worker/<entry>/worker.ts` + `src/worker/<entry>/wrangler.jsonc` のペアを entry ごとに配置 (Step 7 → Step 8 user-gate refinement で確定、`worker/` 親ディレクトリで複数サーバレス関数の性格を構造的に明示)。`wrangler deploy --config src/worker/<entry>/wrangler.jsonc` を entry ごとに実行することで個別デプロイが成立する。ms-01 では `src/worker/health/` + `src/worker/bff/` の **2 entry を雛形として配置** (intent-spec SC-5 = `find` で `worker.ts` ≥ 2 件、`find` は src 配下から再帰検索のため新パスでも変わらず 2 件をカウント)。

- **根拠**: 「マイクロサービス境界としてのプラグイン分割」と「サーバレスアーキテクチャ原則」の両立。ソース管理単位を 1 つに保ちつつ、デプロイ単位は責務 / スケーリング特性ごとに独立させる
- **同原則の Web フロント / IdP への適用**: 可能だが、ms-01 では単一サーバ (SSR + loader / action 一体) として開始。必要時に分割する

### D-5: プロジェクト命名規約

| プロジェクト       | パッケージ名 / `name`   | 配置                            | 役割                                                               |
| ------------------ | ----------------------- | ------------------------------- | ------------------------------------------------------------------ |
| バックエンド       | `feed-platform-backend` | `js/app/feed-platform-backend/` | 入力 / 出力アダプタ / 永続化 / 定期実行 / AI 要約 / リソースサーバ |
| Web フロントエンド | `feed-platform-web`     | `js/app/feed-platform-web/`     | Hono + Remix v3 ベースの SSR + 軽量 BFF                            |
| 認証基幹サーバ     | `identity-provider`     | `js/app/identity-provider/`     | OIDC / OAuth 2.1 における Identity Provider (汎用認証基幹)         |

backend の各 entry は wrangler 上の `name` を **`feed-platform-backend-<entry>`** プレフィックス規約に従う (例: `feed-platform-backend-health` / `feed-platform-backend-bff`)。これにより同一バックエンドプロジェクト内で複数 entry が Cloudflare Workers 上に名前衝突なく共存できる (intent-spec Q2.11、本 ms-01 の design.md M-1〜M-4)。

`identity-provider` を `feed-platform-*` 名前空間に含めない理由は、他システムからの再利用視野 (ADR-02 で詳細を起票)。

### D-6: 実行環境 = Cloudflare Workers (バックエンド = wrangler 直接 / Web/IdP = Vite + Remix v3)

ロードマップ Intent の「サーバレス原則」を **Cloudflare Workers** として具現化する (intent-spec Q2.12)。

- **バックエンド (`feed-platform-backend`)**: **wrangler 直接実行** (`wrangler deploy --config src/worker/<entry>/wrangler.jsonc`)。Vite ビルドを介さず、Cloudflare Workers ランタイムに直接デプロイ。`vite.config.ts` には `build` task を定義せず、Vite+ が `build` 未定義パッケージを `vp run -r build` から auto-skip する機構を活用 (`rss-graphql/vite.config.ts` と同等)。`setup` フェーズで `wrangler types` 経由の `worker-configuration.d.ts` 生成のみが走る
- **Web フロント (`feed-platform-web`) / 認証基幹サーバ (`identity-provider`)**: **Vite + Remix v3 + Cloudflare Workers** (`js/app/hono-remix-v3-cloudflare-example` 最新構成踏襲)。`vite build` でビルド出力 (`dist/client/`)、`wrangler deploy` でデプロイ
- **テスト**: vp (Vitest)。ms-01 段階では設定 1 個のみ (root or 単一プロジェクト共通設定 = `vite-plus/test`、vitest.config 新設しない)
- **CI / 本番デプロイ自動化は本 ms-01 非スコープ** (ロードマップ Intent `roadmap.md:47` の非スコープ事項)、現状は手動デプロイ

その他の常時運用設定:

- **`compatibility_flags: ["nodejs_compat"]` を全プロジェクトの `wrangler.jsonc` で採用** (Effect / Hono / `crypto.randomUUID` 等が要求するため)
- **`observability.enabled: true` + `head_sampling_rate: 1`** を全プロジェクトの `wrangler.jsonc` で採用 (`hono-remix-v3-cloudflare-example/wrangler.jsonc:14` 踏襲)
- **Logger 形式選択**: Effect の Logger 形式切替は **`Layer.unwrap` + `Env.Service` 経由**で実行時判定 (`env.ENV === 'production'` ? `Logger.consoleJson` : `Logger.consolePretty()`)。Env Service の値ソースは **`process.env.NODE_ENV`** (wrangler / vite が dev/deploy 時に自動設定する標準ソース、ref: <https://developers.cloudflare.com/workers/wrangler/bundling/#node_env>) を採用し、`wrangler.jsonc.vars.ENV` の独自 vars は不採用。これにより本番 deploy で dev 値が焼き込まれるバグを構造的に予防する。`import.meta.env.PROD` の直参照も不採用
- **Runtime 解放パターン**: TC39 `await using runtime = Runtime.make()` を採用し、try/finally + 明示的 `runtime.dispose()` 呼び出しは不採用 (refinement #2 + Step 7 → Step 8 user-gate refinement: ENV 取得を内部の `Env.layer` に内部化したため `Runtime.make()` の引数も削除済)

### D-7: backend multi-entry 規約 = `src/worker/<entry>/worker.ts` + `src/worker/<entry>/wrangler.jsonc` ペア

バックエンドの multi-entry 構造は以下の規約に従う (本 ms-01 の design.md A-1 / A-5 / M-1〜M-4 で確定 + Step 7 → Step 8 user-gate refinement で `src/worker/<entry>/` 配下に集約):

- **ディレクトリ**: `src/worker/<entry>/` 直下に `worker.ts` と `wrangler.jsonc` を配置 (`worker/` 親ディレクトリで複数サーバレス関数の性格を構造的に明示、`feature/` (共通 Effect skeleton) と並列に配置することで責務分離を一覧可能にする)
- **wrangler `name` フィールド**: `feed-platform-backend-<entry>`
- **wrangler `main` フィールド**: `worker.ts` (相対参照)
- **`compatibility_date` / `compatibility_flags` / `observability` / `placement`**: 各 entry の `wrangler.jsonc` 内で個別に明示記述 (共通設定の自動継承は採用しない、`hono-remix-v3-cloudflare-example` の規約踏襲)
- **`vite.config.ts` の setup task**: 各 entry に対して `wrangler types` を呼ぶ子 task をぶら下げる fan-out 構造 (`setup:cloudflare:<entry>`)
- **ms-01 で配置する 2 entry**: `src/worker/health/` (`/health` 200 OK) + `src/worker/bff/` (将来のリソースサーバ予告)

### Alternatives considered

| Option          | Summary                                                                                     | Adopted / Rejected | Rationale                                                                                                                                                |
| --------------- | ------------------------------------------------------------------------------------------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A** (Adopted) | `js/` 単一ワークスペース + 3 プロジェクト分離 + Cloudflare Workers + Hono/Remix v3 + Effect | Adopted            | 既存資産との整合性最大、参照実装が既存、サーバレス原則を構造的に保証                                                                                     |
| **B**           | 単一プロジェクト (`js/app/feed-platform/`) で backend + web + IdP を統合                    | Rejected           | 技術選定が大きく異なる (= wrangler 直接 vs Vite + Remix v3)、IdP の汎用化方針と矛盾 (`identity-provider` を `feed-platform-*` 名前空間外に置けない)      |
| **C**           | Web フロント / IdP も wrangler 直接実行 (Vite ビルドを介さない)                             | Rejected           | Remix v3 + Hono の SSR 統合は Vite 経由が既存実証パターン (`hono-remix-v3-cloudflare-example`)、Vite を捨てると Remix v3 の HMR / build 最適化が失われる |
| **D**           | `mbt/` (MoonBit) または `go/` ワークスペースを採用                                          | Rejected           | 関連スキル群が `js/` 中心、参照実装も `js/` 中心、CQRS / イベントソーシングの参照実装が `mbt/` / `go/` には存在しない                                    |
| **E**           | バックエンドを最初から複数プロジェクトに分割 (entry 単位)                                   | Rejected           | YAGNI 違反 + ソース管理単位が肥大化 + 共通 Effect skeleton を 1 プロジェクト内で再利用可能なメリットを失う                                               |

## Consequences

本決定束による影響範囲を「新規追加 / 既存影響 / 将来制約」の 3 軸で記述する。

### Newly added

- **3 プロジェクトの最小雛形が `js/app/` 直下に配置**:
  - `js/app/feed-platform-backend/` (`src/feature/{env,greeting,health,runtime/server,runtime/hono}.ts` + `src/feature/health.test.ts` + `src/worker/{health,bff}/{worker.ts,wrangler.jsonc}`)
  - `js/app/feed-platform-web/` (`app/{entry.worker.ts, app.tsx, routes.ts, assets/entry.ts, ui/document.tsx}` + `app/feature/<5 ファイル>` + `app/feature/{greeting,health}.test.ts`)
  - `js/app/identity-provider/` (T-F〜T-H 同形構造、test ファイルも `app/feature/{greeting,health}.test.ts`)
  - test ファイルは検証対象 module の隣に colocation 配置 (Step 7 → Step 8 user-gate refinement で確定、describe ラベルは module 名 (`'Health'` / `'Greeting'`)、import は relative path)
- **3 プロジェクト共通の Effect skeleton 5 ファイル** (env.ts = `Layer.succeed` / greeting.ts = `Layer.sync` / health.ts = `Layer.effect` / runtime/server.ts = `ManagedRuntime` + `Layer.unwrap` 経由 Logger 判定 / runtime/hono.ts = `await using` middleware) — design.md CC-7
- **wrangler.jsonc 構造規約**: `compatibility_flags: ["nodejs_compat"]` + `observability.enabled: true` + `head_sampling_rate: 1` + (backend のみ) `name: feed-platform-backend-<entry>` プレフィックス
- **vp (Vite+) task 規約**: `vite.config.ts` 内 `run.tasks` に `setup` (および web/IdP は `build`) を定義 (CLAUDE.md `Standard Tasks` 節準拠、backend は `build` 未定義 = Vite+ auto-skip)。`check` / `fix` / `test` は root の `vite.config.ts` 経由で workspace-wide に提供される
- **Service tag namespace 規約**: `@app/<project-name>/feature/<name>/Service` (saas-example 踏襲、design.md CC-6)

### Existing impact

- **monorepo `pnpm-workspace.yaml`** の workspace パターン (`js/app/*`) によって自動的に 3 プロジェクトが workspace に組み込まれる (追加変更不要)
- **既存 CI ワークフロー (`.github/workflows/ci.yaml`)** の `vp run --parallel ci` ジョブが追加変更なしで 3 プロジェクトを取り込む (CC-9)
- **既存スキル (`effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp` / `remix`)** は Project A/B/C すべてで活用される (= 本 ADR の規約に組み込まれる)
- **`hono-remix-v3-cloudflare-example`** は Web フロント / IdP の参照実装として今後も保守対象に留まる (削除しない)
- **`saas-example`** は backend の Effect skeleton 雛形参照として今後も保守対象に留まる
- 実装時の deviation: `effect@4.0.0-beta.60` (catalog 採用版) は `ServiceMap.Service` 非対応のため、design.md 当初記述の `ServiceMap.Service` は実装上 **`Context.Service`** に置換 (saas-example の整合性踏襲、TODO.md T-B notes)。CC-6 の Service tag namespace 規約は維持
- Step 7 → Step 8 user-gate refinement: backend entry 配置を `src/<entry>/` から **`src/worker/<entry>/`** に変更 (User 要望、worker 群と feature 群の責務分離をディレクトリ構造で明示するため)。`src/feature/` は src 直下を維持。詳細は design.md "Deviation note (Step 7 → Step 8 user-gate-driven path restructure)" / task-plan.md "Path restructure deviation note" 参照
- Step 7 → Step 8 user-gate refinement (ENV detection): ENV 取得方法は **`process.env.NODE_ENV` (wrangler / vite 自動設定)** とする (User 要望、本番 deploy で dev 値が焼き込まれるバグの根本予防)。`feature/env.ts` × 3 に production code 用 `Env.layer` (`Layer.sync` from `process.env.NODE_ENV`) を新設し、test 用 `Env.makeLayer` は維持。`feature/runtime/{server,hono}.ts` × 3 + `worker.ts` × 2 + `app.tsx` × 2 + `wrangler.jsonc` × 4 を整合更新。詳細は design.md "Deviation note: ENV detection switched from `wrangler.jsonc.vars.ENV` to `process.env.NODE_ENV`" 参照
- Step 7 → Step 8 user-gate refinement (test placement): test ファイル配置は **検証対象 module の隣に置く `feature/<name>.test.ts` colocation 形** とする (User 要望「smoke.test.ts は全て検証ロジックの近くに .test.ts を作成」)。5 件の `feature/<name>.test.ts` (backend `feature/health.test.ts` 1 件 + web/IdP 各 `feature/{greeting,health}.test.ts` 2 件) を配置。describe ラベルは module 名、import は relative path。test 件数 (5 件) と PASS/FAIL 振る舞いは不変。詳細は design.md "Deviation note: Test placement switched to feature/<name>.test.ts colocation" / task-plan.md "Test placement deviation note" 参照

### Constraints going forward

後続マイルストーン (ms-02〜ms-10) は以下の不変制約を遵守する:

- **3 プロジェクト構成は不変**: ms-02 以降で 4 番目のプロジェクトを追加する場合、その判断は本 ADR を Superseded する形で別 ADR を起票してから実施する
- **backend multi-entry 規約 (`src/worker/<entry>/worker.ts` + `wrangler.jsonc`、`name: feed-platform-backend-<entry>`)** は ms-02 以降でも維持される。新 entry 追加手順は design.md M-1 に従う
- **Cloudflare Workers 以外のサーバレス実行環境** (AWS Lambda / Vercel Edge / 他) への対応は本 ADR の射程外 (ロードマップ Intent 非スコープ `roadmap.md:47`)
- **Effect Service の命名規約 (Service tag namespace)** = `@app/<project-name>/feature/<name>/Service` は ms-02 以降の Service 追加でも踏襲する
- **Logger 形式判定は `Layer.unwrap` + `Env.Service` 経由** (= `import.meta.env.PROD` 直参照禁止) を ms-02 以降でも維持。**Env Service の値ソースは `process.env.NODE_ENV` (wrangler / vite 自動設定) を単一ソースとし、`wrangler.jsonc.vars.ENV` の独自 vars は持たない** 規約も ms-02 以降に継承 (本番 deploy で dev 値が焼き込まれるバグの根本予防、Step 7 → Step 8 user-gate refinement で確定)
- **Runtime 解放は `await using` パターン** (= 明示的 `runtime.dispose()` 禁止) を ms-02 以降でも維持。`Runtime.make()` は引数なし (= ENV は内部 `Env.layer` 経由) を維持
- **Web UI レンダリング戦略**: ms-01 では素朴な `c.render(<Document>...)` のみ。`createPageOrFrame` パターン採用は ms-04 (期間限定共有 UI) / ms-07 (出力プラグイン基盤) の Step 3 (Design) で確定 (design.md L1062-1069 委譲)
- **テスト設定の分離は需要発生時のみ**: ms-01 段階では vp (Vitest) 設定 1 個のみ。プロジェクトごとの分離 / カスタマイズは ms-02 以降の必要時に実施
- **テストファイルは検証対象 module の隣に colocation** (= `feature/<name>.test.ts` 形、Step 7 → Step 8 user-gate refinement で確定) を ms-02 以降でも維持。新規 Service module を `feature/auth.ts` 等で追加する際は、隣に `feature/auth.test.ts` を置く規約を踏襲する。describe ラベルは module 名、import は relative path

### Trade-offs と緩和策

- **Pros**: ロードマップ Intent の architectural constraints を構造的に保証 / 既存資産 (`hono-remix-v3-cloudflare-example` / `saas-example` / `rss-graphql`) を最大活用 / 後続 9 マイルストーンが一貫した雛形上で進む / vp (Vitest) + Ultracite の既存集約規約に乗る
- **Cons**: backend と Web フロントで entry ファイル命名が `worker.ts` ↔ `entry.worker.ts` の微妙な不整合 / `wrangler.jsonc` の共通設定 (`compatibility_date` / `observability` 等) が entry ごとに重複記述される
- **Mitigation**: 命名差は用途差 (multi-entry 直 vs Vite 経由) で説明可能 (design.md A-5 / B-1 で明記) / 共通設定の重複は entry 数が一桁の間は問題ない (将来 entry 数が膨らむ場合は共通設定の SSOT 化を検討)

## References

- **Roadmap-scoped record**: this ADR is the durable source for the ms-01 workspace foundation decisions used by ms-02〜ms-10.
- **Related Roadmap**: `docs/roadmap/feed-platform/roadmap.md` (アーキテクチャ的制約 / ms-01〜ms-10 マイルストーン定義)
- **Related Milestone**: `docs/roadmap/feed-platform/milestones/ms-01-workspace-foundation.md`
- **Related ADR**: `docs/adr/2026-05-05-identity-provider-and-authn-authz-architecture.md` (ADR-02、`identity-provider` の汎用化方針 + 認証認可アーキテクチャ。General mode、本 ADR と対をなす)
- **既存参照実装**: `js/app/hono-remix-v3-cloudflare-example/` (Web フロント / IdP の踏襲元) / `js/app/saas-example/` (Effect skeleton の踏襲元) / `js/app/rss-graphql/`
- **Implementation commits**: T-A `2881bfa` / T-B `49784f2` / T-C `7812ba6` / T-D `2460fe9` / T-E `12cab81` / T-F `8fa4df2` / T-G `ee21531` / T-H `b5d0bba` / T-I `da5dfaf` / T-J `80f3ca8`
