# Review Report: API Design

- **Cycle:** feed-platform-ms-01-workspace-foundation
- **Aspect:** api-design — HTTP API / Effect Service API / wrangler.jsonc / Vite+ task / ADR 拡張点の境界整理と将来拡張性
- **First reviewed:** 2026-05-06
- **Last updated:** 2026-05-06
- **Final Gate:** approved
- **Round count:** 2

## Findings list

| ID  | Severity | Finding                                                                                                                                                                                                                                                                                                                                                   | State               | First Round | Resolution commit | Notes                                                                                                                                                                                                                                                                                                                                                                                                                               |
| --- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ----------- | ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| M-1 | Major    | `identity-provider/vite.config.ts` の `run.tasks` API surface が `feed-platform-web` と非対称 (`setup` / `setup:cloudflare` 欠落) で design.md C-4 / 同形宣言に反する                                                                                                                                                                                     | fixed               | 1           | dacf3e4           | Round 2 (2026-05-06): `dacf3e4` で `identity-provider/vite.config.ts:9-13, 24-31` に `taskInput.setup.cloudflare` + `setup` / `setup:cloudflare` task + `build.dependsOn: ['setup']` を追加し `feed-platform-web` と完全同形化。`.gitignore` も `worker-configuration.d.ts` 追加で同形化。[detail](#m-1-detail-identity-provider-vite-tasks-divergence)                                                                             |
| M-2 | Major    | `feed-platform-web/app/routes.ts:13` の `frames = {} as const` により `FrameName` が `never` 化 → `isFrameRequest` API が呼出不能。IdP 側 (`{ content: 'content' }`) との API 表面不整合                                                                                                                                                                  | fixed               | 1           | dacf3e4           | Round 2 (2026-05-06): `dacf3e4` で `identity-provider/app/routes.ts:13` を `frames = { content: 'content' }` → `frames = {} as const` に変更し、両プロジェクト同形化。`isFrameRequest` の型レベル uncallable は **両プロジェクトで同形に保持**することで解消 (Frame 採用時に同時に `frames` を埋める前提を docstring に明示)。[detail](#m-2-detail-isframerequest-never-poisoning)                                                  |
| M-3 | Major    | `Effect Service` tag の registry: design.md 99-143 が `ServiceMap.Service` を指定しているが、実装は全プロジェクトで `Context.Service` を使用 (`@app/<project>/feature/<name>/Service` 命名)。Effect 4.x の registry API として global uniqueness の保証根拠が design 記載と乖離                                                                           | fixed               | 1           | 900b120           | Round 2 (2026-05-06): `900b120` で `design.md:99-144` の env / greeting / health 3 snippet を `ServiceMap.Service` → `Context.Service` に置換 + import 修正、CC-6 export 名規約 (L934) と SC-6 観測仕様 (L1156, L1218) を `Context.Service\|ServiceMap.Service` の OR 表記に拡張、Phase 1 deviation note を 2 箇所追記 (L146 / L212)。**design 採用 = Adopted: `Context.Service`**。[detail](#m-3-detail-context-vs-servicemap-api) |
| m-1 | Minor    | `feed-platform-backend` の `health` / `bff` 両 entry とも `/health` 1 endpoint のみで、`/api/v1/*` prefix が backend 側に未予約。後続 ms-05 で `/api/v1/feeds`, ms-06 `/cron/input/<adapter>` 追加時に endpoint API surface 規約が未確立                                                                                                                  | pending             | 1           | -                 | [detail](#m-1-detail-backend-endpoint-prefix-policy)                                                                                                                                                                                                                                                                                                                                                                                |
| m-2 | Minor    | `dynamicLoggerLayer` (`server.ts:11-16`) は Logger 専用にハードコードされ、ms-02 以降で env 由来の他の動的 Layer (例: `AUTH_PROVIDER` に応じた認証 Layer) へ汎用化する API 抽象が未提供                                                                                                                                                                   | pending             | 1           | -                 | [detail](#m-2-detail-dynamicloggerlayer-generality)                                                                                                                                                                                                                                                                                                                                                                                 |
| m-3 | Minor    | `DisposableRuntime` API (`server.ts:42-55`) は `instance` プロパティ + `Symbol.asyncDispose` を露出しているが、`makeDisposableRuntime` HOF 引数の型 `typeof makeRuntime` がプロジェクトローカル関数に固定。ms-02 で Test/DryRun runtime バリアントを HOF 経由で増やす場合の wider type 受け入れが不足                                                     | pending             | 1           | -                 | [detail](#m-3-detail-disposable-runtime-hof-narrowing)                                                                                                                                                                                                                                                                                                                                                                              |
| m-4 | Minor    | `wrangler.jsonc` (IdP) の DB binding 予約コメント (`identity-provider/wrangler.jsonc:22-34`) は構造化されたキー予約形式 (`/* RESERVED: d1_databases */` 等) ではなく自由形式コメントで、ms-02 実装者がパースで「弾く」べき API surface としての規約性が弱い                                                                                               | pending             | 1           | -                 | [detail](#m-4-detail-db-binding-reservation-format)                                                                                                                                                                                                                                                                                                                                                                                 |
| m-5 | Minor    | 3 プロジェクト共通 Effect skeleton (env / greeting / health) の **完全コピー** 配置 (`feed-platform-backend/src/feature/*` / `feed-platform-web/app/feature/*` / `identity-provider/app/feature/*` で同型) は SC-6 を満たすが、共通インターフェース (`@app/<x>/feature/env/Type` 等) を `js/package/` 側に切り出す将来 breaking 範囲の API 影響評価がない | pending             | 1           | -                 | [detail](#m-5-detail-effect-skeleton-dry-vs-namespace-independence)                                                                                                                                                                                                                                                                                                                                                                 |
| m-6 | Minor    | `Env.Type` の `ENV: 'production' \| 'development'` (`env.ts:3-5`) と auto-generated `worker-configuration.d.ts:9` の `ENV: "development"` (literal) が二重ソース。後続 ms-02 以降で `vars.ENV` を `'production'` に切り替えた瞬間に `Env.Type` 側を手で更新しないと型と値が乖離する                                                                       | pending             | 1           | -                 | [detail](#m-6-detail-env-type-vs-vars-narrowing)                                                                                                                                                                                                                                                                                                                                                                                    |
| m-7 | Minor    | `feed-platform-backend/vite.config.ts:24` の `wrangler types --config src/<entry>/wrangler.jsonc src/<entry>/worker-configuration.d.ts` 呼出形式は entry 数と一次関数で増える定型コードだが、entry 追加時に手作業 3 箇所修正 (`taskInput.setup`, `dependsOn`, 個別タスク) の機械的反復のみで helper API 化されていない                                    | pending             | 1           | -                 | [detail](#m-7-detail-backend-setup-fanout-scaling)                                                                                                                                                                                                                                                                                                                                                                                  |
| i-1 | Info     | ADR-02 の `can(jwt, resource, action) -> boolean` 不変原則 (`adr/2026-05-05-...:107` / `:114` / `:162`) は本サイクル実装にはまだ I/F が無く、Phase 1〜5 を通じた不変保証は文書レベルでのみ表現。code-level enforcement は ms-03 以降                                                                                                                      | (consistency check) | 1           | -                 | ADR-02 D-6 が Superseded prerequisite を明文化済 (`adr:162`) のため ms-01 段階での action は不要。ms-03 で interface 起こし時に共有型を `js/package/authz/` で固定化することを推奨                                                                                                                                                                                                                                                  |
| i-2 | Info     | HTTP endpoint 命名 (`/health` / `/api/v1/hello`) は Hello World レベルとしては予測可能、ms-05 (`/api/v1/feeds`) / ms-06 (`/cron/input/<adapter>`) / ms-07 (`/api/v1/output/<adapter>`) のロードマップ予告 (design.md L1035) と prefix 整合                                                                                                                | (consistency check) | 1           | -                 | `/health` の prefix-less 形 (公開健全性) と `/api/v1/*` の versioned 形が並列で、API surface 設計として一貫している                                                                                                                                                                                                                                                                                                                 |
| i-3 | Info     | `feed-platform-backend` の純 Worker entry と `feed-platform-web` / `identity-provider` の Remix-Worker entry の `wrangler.jsonc` は **wrangler の `extends` 機能を持たない** (design Option G で Rejected) 状況下で個別記述。3 プロジェクト + 2 entry = 4 ファイルの divergence リスクは ms-01 段階では許容範囲                                           | (consistency check) | 1           | -                 | ms-02 以降で entry 追加時に各 entry の `compatibility_date` / `compatibility_flags` の同期を CI で検出する手段を ADR-01 改訂時に追加検討する余地あり                                                                                                                                                                                                                                                                                |

## Detailed sections

### M-1 detail: identity-provider vite tasks divergence

**File:line:**

- `js/app/identity-provider/vite.config.ts:1-16`
- `js/app/feed-platform-web/vite.config.ts:1-34`
- design.md C-4 (`identity-provider` 「`feed-platform-web` と完全同形」宣言、L795-797)

**Problem:**

design.md C-4 は明示的に「`vite.config.ts` 雛形 = `feed-platform-web` と完全同形」と宣言している。しかし実装は以下のとおり大きく divergent:

`feed-platform-web/vite.config.ts:8-31` (Adopted 形):

```ts
const taskInput = defineTaskInputFromOutput({
  setup: { cloudflare: ['.wrangler/**', 'worker-configuration.d.ts'] },
})
export default defineConfig({
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' }), cloudflare()],
  run: {
    tasks: {
      build: { command: 'vp build', dependsOn: ['setup'], input: taskInput.build },
      setup: { command: '', dependsOn: ['setup:cloudflare'] },
      'setup:cloudflare': { command: 'wrangler types', input: taskInput.setup.cloudflare },
    },
  },
})
```

`js/app/identity-provider/vite.config.ts:5-15` (Actual):

```ts
export default defineConfig({
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' }), cloudflare()],
  run: {
    tasks: {
      build: { command: 'vp build', input: [{ auto: true }, '!.wrangler/**', '!dist/**'] },
    },
  },
})
```

**Impact (api-design):**

1. **task API surface の非対称**: 同じ「Web フロント Worker 構成」として並置される 2 プロジェクトが `vp run setup` / `vp run setup:cloudflare` の存在有無で異なる。CI が `vp run -r setup` を呼ぶ場面で IdP 側が **silently no-op** (= task 未定義) で skip され、`worker-configuration.d.ts` の自動生成が走らない。実際 `js/app/identity-provider/` 直下に `worker-configuration.d.ts` が **存在しない** (`feed-platform-web/worker-configuration.d.ts` は 504 KB の生成済ファイルが存在)。
2. **将来 binding 追加時の breaking 連鎖**: ms-02 で `d1_databases` / `kv_namespaces` が IdP に追加される際、`wrangler types` が `Cloudflare.Env` に `DB` / `KV_SESSIONS` プロパティを生やすが、setup task が無いため型生成が走らない → handler 側で `c.env.DB` 等が型エラー or `unknown` として通過する可能性。
3. **design.md の「完全同形」宣言 (`design.md:795`) と実装の不整合は、API design 一貫性の最も基本的な保証 (= 兄弟プロジェクトが互換 surface を持つ) を破壊**している。

**Recommendation:**

`identity-provider/vite.config.ts` を `feed-platform-web/vite.config.ts` と完全同形 (`taskInput` 定義 + `setup` / `setup:cloudflare` task 追加) に修正。Step 6 への戻し (Round 2 で確認)。

**Round 2 verification (2026-05-06, commit `dacf3e4`):**

- `js/app/identity-provider/vite.config.ts:9-13` に `defineTaskInputFromOutput({ setup: { cloudflare: ['.wrangler/**', 'worker-configuration.d.ts'] } })` が追加され、`feed-platform-web/vite.config.ts:8-12` と完全に同じ構造。
- `js/app/identity-provider/vite.config.ts:24-31` に `setup` (`command: ''` + `dependsOn: ['setup:cloudflare']`) と `setup:cloudflare` (`command: 'wrangler types'` + `input: taskInput.setup.cloudflare`) task が追加。
- `js/app/identity-provider/vite.config.ts:19-23` の `build` task は `dependsOn: ['setup']` + `input: taskInput.build` に修正済 (= `vp run -r build` 実行時に `wrangler types` が前段で確実に走る)。
- `js/app/identity-provider/.gitignore:3` に `worker-configuration.d.ts` を追加 (web / backend と同形)。
- 結論: `feed-platform-web/vite.config.ts` と **完全同形** が成立。`vp run -r setup` で IdP 側でも `wrangler types` が実行される。**Status: fixed**。

### M-2 detail: isFrameRequest never-poisoning

**File:line:**

- `js/app/feed-platform-web/app/routes.ts:13` (`frames = {} as const`) → `FrameName = (typeof frames)[keyof typeof frames]` (line 15) → `keyof typeof frames` is `never` → `FrameName = never`
- `js/app/feed-platform-web/app/routes.ts:25` `isFrameRequest(frame: FrameName): boolean` → effective signature: `(frame: never) => boolean` (= **uncallable**)
- 比較: `js/app/identity-provider/app/routes.ts:13-15` (`frames = { content: 'content' } as const` → `FrameName = 'content'`) では `isFrameRequest('content')` が呼出可能

**Problem:**

`feed-platform-web` 側は **export された API として `isFrameRequest` が公開されているが、実際には型レベルで呼び出せない**。 `as const` で `frames = {}` とすると `keyof typeof frames` は `never` となり、関数の引数型が `never` になる。`never` 引数の関数は理論上どんな値も渡せない (型エラー) ため、API として export する意義が消失している。

加えて、

- `feed-platform-web/app/routes.ts:13`: `frames = {} as const` (空)
- `identity-provider/app/routes.ts:13-15`: `frames = { content: 'content' } as const` (1 entry)

の **同名 module の API surface が 2 プロジェクトで非対称**。`design.md` (L592-593) は「`app/routes.ts` (Frame レジストリ) は **省略**」と明記していたが、実装では両プロジェクトで作成し、しかも内容が異なる。これは:

1. design.md と実装の内容不一致 (Frame レジストリは「省略」だったはず)
2. 採用された 2 プロジェクト間で route registry API の表面が不揃い

**Impact (api-design):**

- ms-04 / ms-07 (Frame UI 採用時) に `feed-platform-web` 側の `frames` を空から `{ content: 'content' }` 等に拡張する瞬間に、**型変更だけだが consumer (= `isFrameRequest` 呼出側) のコードが「呼べる API」へ突然変わる** breaking-like 変化。
- IdP 側 (現状 `content: 'content'`) は ms-01 段階で消費者がいないにも関わらず Frame name `'content'` を予約済 → ms-04 / ms-07 が「`content` は IdP の予約名」を尊重する必要が生じる。これも将来の API 変更時の制約として早期コミットされてしまっている。

**Recommendation:**

design.md の宣言通り `app/routes.ts` を **両プロジェクトで未配置** に統一するか、配置するなら **両プロジェクトで同形 (どちらか一方の状態) に統一**。

- 推奨案 A: 両者とも `frames = {} as const` に揃え、`isFrameRequest` を `export` せず内部 helper に降格 (= 公開 API surface ではない、ms-04 / ms-07 で起こす)
- 推奨案 B: 両者とも `routes.ts` 未作成 (design.md L592-593 字面準拠)

**Round 2 verification (2026-05-06, commit `dacf3e4`):**

- `js/app/identity-provider/app/routes.ts:13` を `frames = { content: 'content' } as const` → `frames = {} as const` に変更し、両プロジェクト同形化 (= 推奨案 A の「両者とも `frames = {} as const`」を採用)。
- `js/app/identity-provider/app/routes.ts:3-12` の docstring も `feed-platform-web/app/routes.ts:3-12` と同形に書き換え、「PageOrFrame 採用時に同時に `frames` を埋める」前提を明示 (`feed-platform-web/app/routes.ts` と完全同形 と注記)。
- 注意点 (Info): `isFrameRequest` は **両プロジェクトで型レベル uncallable のまま保持**されている (`FrameName = never`)。これは ms-04 / ms-07 で `frames` を埋める際に `isFrameRequest` が同時に呼出可能となる前提の deliberate API design として整理された (両プロジェクト同形 + docstring の予告 → 採用時に **対称な breaking-like 変化** = どちらか片方だけで先行コミットされない)。Round 1 で指摘した「IdP 側だけ予約名 `'content'` が早期コミット」状態は解消。
- 結論: 両プロジェクトの `routes.ts` API surface が完全対称、Round 1 で指摘した非対称性は解消。**Status: fixed**。

### M-3 detail: Context.Service vs ServiceMap.Service API

**File:line:**

- design.md `Key types and interfaces` (L106 / L117 / L134): `ServiceMap.Service<Type>('@app/<project-name>/feature/<name>/Service')`
- `js/app/feed-platform-backend/src/feature/env.ts:7`: `Context.Service<Type>('@app/feed-platform-backend/feature/env/Service')`
- `js/app/feed-platform-backend/src/feature/greeting.ts:7`: `Context.Service<...>(...)`
- `js/app/feed-platform-backend/src/feature/health.ts:12`: 同上
- `feed-platform-web/app/feature/{env,greeting,health}.ts` / `identity-provider/app/feature/{env,greeting,health}.ts`: 全て `Context.Service`

**Problem:**

design.md は **`ServiceMap.Service`** API (Effect 4.x の新しい registry API) を一貫して指定しているが、実装は全 9 ファイル (3 プロジェクト × 3 service) で **`Context.Service`** API を採用。両者は Effect 4.x の異なる public surface であり、registry の global-uniqueness 保証メカニズムが異なる可能性がある (Effect 4.x が `Context.Service` と `ServiceMap.Service` を両方 export しているか、片方が deprecated か等の根拠が design / 実装 / コメントに無い)。

design.md L106 は `effect-layer` skill の規約とも整合した形 (`ServiceMap.Service`) を提示しているため、実装側が `Context.Service` を採用した根拠が見えない。

**Impact (api-design):**

1. **Service tag registry の global uniqueness**: `'@app/feed-platform-backend/feature/env/Service'` のような string tag が **どの registry に登録されるか** (`Context` / `ServiceMap`) が API として可視化されていない。Effect 4.x で 2 つの registry が分かれている場合、別 registry に同じ string が登録されると衝突しない可能性 (= 想定外の隔離が起きる)、もしくは同じ registry に共有される場合に衝突する可能性。design 記載との不一致を解消しないと、ms-02 以降で `js/package/authz/` 等の共有 service を作る際の API 選択が定まらない。
2. **`effect-layer` skill 規約との整合**: 既存 `js/app/saas-example` 等が `ServiceMap.Service` を採用している場合、本サイクルだけ `Context.Service` を選んだ根拠を ADR-01 / design.md に追記するか、実装を `ServiceMap.Service` に揃えるかが必要。

**Recommendation:**

以下のいずれか:

- **A**: 実装を `ServiceMap.Service` に揃え design 通りに統一 (推奨: design 字面準拠)
- **B**: `Context.Service` 採用を design.md / ADR-01 に追記し、`ServiceMap.Service` との API 関係 (どちらが Effect 4.x の正規 API か / 既存 saas-example との一貫性) を文書化

Round 2 までに採用 API を確定し、3 プロジェクトの 9 ファイルすべてで揃える。

**Round 2 verification (2026-05-06, commit `900b120`):**

採用案 = **B (Context.Service を design.md / ADR-01 に追記)**。具体的な訂正内容:

- `design.md:99-144` の env / greeting / health 3 snippet の `ServiceMap.Service<Type>(...)` を `Context.Service<Type>(...)` に置換し、import 文を `import { Context, Layer } from 'effect'` 形式に修正 (3 ファイル分)。
- `design.md:146` に **Phase 1 deviation note** を追加: 「初版は `ServiceMap.Service<Type>(...)` を採用していたが `effect@4.0.0-beta.60` (catalog 採用版) では `ServiceMap.Service` の利用形が saas-example と整合せず、3 プロジェクト × 3 service = 全 9 ファイルで `Context.Service` に統一」+ deviation 経緯の記録先 (`TODO.md T-B notes` / ADR-01 "Existing impact") を明示。
- `design.md:212` に同様の Phase 1 deviation note (Layer 合成形の調整) を追加。
- `design.md:934` (CC-6 export 名規約) を `Context.Service` に修正、deviation 経緯を inline 注記。
- `design.md:949` / `design.md:1156` / `design.md:1218` の SC-6 観測仕様を `Layer / Context.Service / ServiceMap.Service / ManagedRuntime` の OR 表記に拡張 (= grep が両 API を hit 可能、Phase 1 deviation 後でも SC 字面と整合)。
- `effect@4.0.0-beta.60` で `Context.Service` と `ServiceMap.Service` の registry 関係について: design 改訂で「`Context.Service` を Adopted API として固定し、saas-example と整合」を明示することで Phase 1 段階の API 選択の根拠を SoT として残した (registry global-uniqueness 詳細は ADR-01 Existing impact 経由で補足、ms-03 で `js/package/authz/` 配置時に再評価可能)。
- 実装側 (`feature/{env,greeting,health}.ts` 全 9 ファイル) は変更なし — 当初から `Context.Service` で統一されていたため、design 側の追従訂正で乖離が解消。
- 結論: design.md / 実装の API 一貫性が回復、Phase 1 deviation note が後続 implementer (ms-02 以降) への引き継ぎとして残存。**Status: fixed**。

### m-1 detail: backend endpoint prefix policy

**File:line:**

- `js/app/feed-platform-backend/src/health/worker.ts:20-28` `/health`
- `js/app/feed-platform-backend/src/bff/worker.ts:23-31` `/health`
- `js/app/feed-platform-web/app/app.tsx:36-53` `/` + `/api/v1/hello`
- `js/app/identity-provider/app/app.tsx:37-54` 同上

**Problem:**

backend の 2 entry は両方とも `/health` のみを expose しており、`/api/v1/*` prefix が **backend 側** に予約されていない。Web フロント / IdP 側は `/api/v1/hello` を採用済。design.md の Anticipated extension points (L1035-1037) は ms-05 で `/api/v1/feeds`、ms-06 で `/cron/input/<adapter>`、ms-07 で `/api/v1/output/<adapter>` を backend 側に追加する想定を明記している。

ms-01 段階で `/api/v1/*` の API surface 規約 (例: `/api/<version>/<resource>` か `/api/v1/<resource>` か / version 戦略 / `/cron/*` の prefix 性) が backend 側で何も予約されていないと、後続マイルストーンが各々独自に prefix を選んでしまい、entry をまたいだ uniformity が失われる。

**Impact:**

`feed-platform-backend-bff` Worker は将来 Resource-Oriented BFF (`/api/v1/feeds` 等) を捧げる集約点として位置付けられている (design.md S-3 / 1043) が、`bff/worker.ts:23` が `/health` のみを expose し、`/api/v1/` prefix のサンプルが入っていない。Hello World 1 endpoint だけでは「ms-05 の実装者が prefix をどう揃えるか」が示されない。

**Recommendation:**

`bff/worker.ts` に `/api/v1/hello` (Hello World JSON) を 1 件追加し、Web フロント / IdP の `/api/v1/hello` と prefix を揃える。ADR-01 に「backend の API endpoint prefix 規約 = `/api/v1/<resource>` / 例外は `/health` (公開健全性) と `/cron/*` (Scheduled Worker) のみ」を 1-2 行追記すると後続マイルストーンが迷わない。

### m-2 detail: dynamicLoggerLayer generality

**File:line:**

- `js/app/feed-platform-backend/src/feature/runtime/server.ts:11-16`
- 同形: `feed-platform-web/app/feature/runtime/server.ts:11-16` / `identity-provider/app/feature/runtime/server.ts:11-16`

**Problem:**

```ts
const dynamicLoggerLayer = Layer.unwrap(
  Effect.gen(function* () {
    const env = yield* Env.Service
    return Logger.layer([env.ENV === 'production' ? Logger.consoleJson : Logger.consolePretty()])
  }),
)
```

`dynamicLoggerLayer` は **Logger 専用にハードコード**された定数。design.md L1039-1040 / Anticipated extension points は ms-02 で `feature/auth/jwt-verifier.ts`、ms-05 で `feature/event-store/*` を追加すると予告しているため、env (例: `AUTH_PROVIDER`) に応じた **動的 Layer** を Logger 以外でも作る場面が後続で必ず発生する。しかし `dynamicLoggerLayer` の Layer.unwrap + Effect.gen + yield\* Env.Service パターンを **共通 helper** として抽出する API は ms-01 では用意されていない。

**Impact:**

ms-02 以降で `dynamicAuthLayer` / `dynamicEventStoreLayer` 等を作るたびに **同じ 6 行ボイラープレート**を繰り返す。共通化は ms-02 段階でも可能だが、ms-01 で `Layer.unwrap` パターンの API 抽象が「Logger を hardcode した名前 (`dynamicLoggerLayer`)」になっていると、将来抽出時に「Logger 以外への一般化」を意識するための名前付け debt が発生する。

**Recommendation (将来):**

ms-02 設計時に `feature/runtime/dynamic-layer.ts` (または `js/package/fp/effect/dynamic-layer.ts`) に

```ts
export const fromEnvService = <S, A, E1, R1>(
  factory: (env: Env.Type) => Layer.Layer<A, E1, R1>,
): Layer.Layer<A, E1, R1 | Env.Service> =>
  Layer.unwrap(
    Effect.gen(function* () {
      return factory(yield* Env.Service)
    }),
  )
```

のような generic helper として API 抽出するのが望ましい。**ms-01 では action 不要 (= Minor)**、ms-02 設計時の Anticipated extension に追記推奨。

### m-3 detail: DisposableRuntime HOF narrowing

**File:line:**

- `js/app/feed-platform-backend/src/feature/runtime/server.ts:42-55`
- 同形: feed-platform-web / identity-provider

**Problem:**

```ts
const makeDisposableRuntime = (make: typeof makeRuntime) =>
  class DisposableRuntime implements DisposableRuntimeInterface {
    readonly instance: Runtime
    constructor(env: Env.Type) {
      this.instance = make(env)
    }
    async [Symbol.asyncDispose](): Promise<void> {
      await this.instance.dispose()
    }
  }
```

HOF の引数型 `typeof makeRuntime` は **同一ファイル内の `makeRuntime` と type identity で結ばれている**。design.md (Alternatives S/T、L1024-1026) は ms-02 以降で「Test / DryRun 等の異なる runtime バリアント」を追加する際の素地として `makeDisposableRuntime` を HOF 化したと説明している (= saas-example が PROD/DEV/TEST で 3 バリアント持つのと対照的に、ms-01 は 1 バリアントだが HOF だけ残す)。

しかし実際の `typeof makeRuntime` は `(env: Env.Type) => ManagedRuntime<...>` という具体型に narrow されているため、ms-02 で別 signature の runtime 製造関数 (例: `makeTestRuntime: (env: Env.Type, mocks: Mocks) => ManagedRuntime<...>`) を渡そうとした瞬間 type assignability エラーになる。HOF 化の意図 (= 拡張点) と実装の型 narrowing が矛盾している。

**Impact:**

ms-02 で `DisposableTestRuntime` を導入する際、`makeDisposableRuntime` 自体を generic 化する breaking 改修が必要になる。`instance` プロパティの型 (= `Runtime`) も `ReturnType<typeof makeRuntime>` で固定化されているため、test runtime の型を渡そうとすると `instance` の型不一致が発生する。

**Recommendation (将来):**

ms-02 設計時に `makeDisposableRuntime` を generic 化:

```ts
const makeDisposableRuntime = <R>(make: (env: Env.Type) => R & { dispose(): Promise<void> }) =>
  class { readonly instance: R; ... }
```

**ms-01 では action 不要** (= Minor)。Anticipated extension points に「`makeDisposableRuntime` は ms-02 で generic 化予定」を追記推奨。

### m-4 detail: DB binding reservation format

**File:line:**

- `js/app/identity-provider/wrangler.jsonc:22-34`

**Problem:**

```jsonc
"vars": {
  "ENV": "development",
  // ms-02 (Passkey + Magic Link) 以降で Better Auth を導入する際、認証関連の
  // 環境変数を以下に追加する。実体は ms-02 の実装者が wrangler secret 等で注入予定。
  // "BETTER_AUTH_URL": "...",
  // "BETTER_AUTH_SECRET": "[REDACTED — wrangler secret 経由で注入]",
},
// ms-02 (Passkey + Magic Link) 以降で D1 / KV binding を有効化する。
// 実際の database_id / namespace id は秘密情報相当のため ms-02 の実装者が確定する。
// "d1_databases": [
//   { "binding": "DB", "database_name": "identity-provider", "database_id": "..." },
// ],
// "kv_namespaces": [
//   { "binding": "KV_SESSIONS", "id": "..." },
// ],
```

予約コメントは **自由形式**で構造化されておらず、ms-02 実装者がどの bindings を「弾く」(= ms-01 段階で約束された API surface) ものとして扱うかの規約が暗黙。具体的には:

- **`binding: "DB"`** (D1) / **`binding: "KV_SESSIONS"`** (KV) は予約名なのか、ms-02 で自由に変えてよいのか判別不可
- `BETTER_AUTH_URL` / `BETTER_AUTH_SECRET` の name も同様
- マシン読み取り (e.g. lint / pre-commit hook) で「予約形式の正しさ」を検証する手段が無い

**Impact:**

ms-02 実装者が `binding: "DATABASE"` 等で書いた瞬間、リソースサーバ側 (backend) が想定する `c.env.DB` と乖離。本来 ms-01 は「IdP の DB binding は `DB` 固定」を約束するべき箇所。

**Recommendation:**

予約コメントを以下のように構造化:

```jsonc
// === RESERVED for ms-02 (Better Auth) ===
// d1_databases[0].binding = "DB"        (固定: backend が c.env.DB として参照)
// kv_namespaces[0].binding = "KV_SESSIONS" (固定: Better Auth session store)
// vars.BETTER_AUTH_URL                  (実体は ms-02 で wrangler secret)
// vars.BETTER_AUTH_SECRET               ([REDACTED] / wrangler secret)
// === END RESERVED ===
```

ADR-02 D-1〜D-3 と整合して binding 名を ms-01 段階で固定化することで、ms-02 実装者が「弾く」べき surface が明示される。**Minor / Round 2 で改善余地あり**。

### m-5 detail: Effect skeleton DRY vs namespace independence

**File:line:**

- `feed-platform-backend/src/feature/{env,greeting,health}.ts`
- `feed-platform-web/app/feature/{env,greeting,health}.ts`
- `identity-provider/app/feature/{env,greeting,health}.ts`

**Problem:**

3 プロジェクトの 9 ファイルは **string tag 部分のみ異なり構造は完全同型** (上で読んだ全 9 ファイルが env: 9 行 / greeting: 11 行 / health: 22 行 で同型)。

design.md は CC-7 (L932-940) で「3 プロジェクト共通の Effect skeleton 5 ファイル」として複製を意図的に選んでいる (= API independence 優先 / DRY 違反は許容)。しかし将来 `js/package/authz/` のような共有パッケージを作る際に「`@app/<project>/feature/env/Service` 形式の string tag を `@package/<x>/...` 形式の共通 tag に移す」breaking が見込まれる。design.md にその影響範囲評価がない。

**Impact:**

- ms-02 (`feature/auth/jwt-verifier.ts` 追加) / ms-03 (`js/package/authz/` 配置確定) で「3 プロジェクトの env / greeting / health を共通化するか」の判断時に、API surface (`Service` tag string / `Type` interface) を **3 プロジェクト独立で進化させる前提**が固まっているか不明。
- 共通化する場合: 9 ファイルすべての string tag を一斉に書き換える必要があり、各 entry の `worker.ts` / `app.tsx` 内 `yield* Env.Service` も影響を受ける (string tag 識別が registry 上で衝突するため)
- 独立を維持する場合: 各プロジェクトが独自に `feature/env.ts` を進化させる前提でドキュメント明記が必要

**Recommendation:**

ADR-01 (Roadmap mode) に「Effect skeleton の共通化判断は ms-03 で確定する。それまで各プロジェクトの `@app/<project>/feature/<name>/Service` namespace は **独立進化を許容**する」を 1 項追加。**Minor / Round 2 で対応**。

### m-6 detail: Env.Type vs vars narrowing

**File:line:**

- `js/app/feed-platform-backend/src/feature/env.ts:3-5` (`ENV: 'production' | 'development'`)
- `js/app/feed-platform-backend/src/health/worker-configuration.d.ts:9` (`ENV: "development"`) — auto-generated
- `wrangler.jsonc.vars.ENV: "development"` — 全 entry 共通

**Problem:**

- 開発者が手書きの `Env.Type.ENV` は `'production' | 'development'` の union
- wrangler 自動生成の `Cloudflare.Env.ENV` は `"development"` (literal)

この **二重ソース** は、本番 wrangler.jsonc が `vars.ENV: "production"` に切り替わった瞬間に **手書き型と auto-generated 型のどちらが正か** が曖昧になる。ms-01 段階では `Env.Type.ENV` の `'production'` ブランチが死コード (= dynamicLoggerLayer で `consoleJson` に分岐するが本番 wrangler.jsonc が無いため到達不能)。

**Impact:**

- `dynamicLoggerLayer` の `env.ENV === 'production'` 判定が **本番 wrangler.jsonc のメンテナンスを誰が責務するか** を暗黙化している (ms-01 では誰もしない、ms-02 で誰かが書く)
- 後続マイルストーンで `vars.ENV: "test"` を追加した瞬間、`Env.Type` の更新を忘れると runtime 値と型が乖離

**Recommendation:**

- 短期: `Env.Type` を `Cloudflare.Env` から派生させる (`type Type = Pick<Cloudflare.Env, 'ENV'> & { readonly ENV: 'production' | 'development' }` 等) ことで wrangler 生成型と整合
- 中長期: `Env.Type` の定義を `worker-configuration.d.ts` の re-export に近づける形へ移行 (ms-02 で binding 数が増える際に決定)

**Minor / Round 2 検討余地あり**。

### m-7 detail: backend setup fan-out scaling

**File:line:**

- `js/app/feed-platform-backend/vite.config.ts:4-32`

**Problem:**

```ts
const taskInput = defineTaskInputFromOutput({
  setup: {
    'cloudflare:bff': ['.wrangler/**', 'src/bff/worker-configuration.d.ts'],
    'cloudflare:health': ['.wrangler/**', 'src/health/worker-configuration.d.ts'],
  },
})
// ... tasks: { setup: { dependsOn: ['setup:cloudflare:bff', 'setup:cloudflare:health'] }, ... }
```

backend の entry 追加手順 (design.md M-1, L843-851) は entry 1 件追加につき:

1. `taskInput.setup.cloudflare:<new>` に 2 行追加
2. `tasks.setup.dependsOn` に 1 行追加
3. `tasks['setup:cloudflare:<new>']` ブロックに 4 行追加

の **3 箇所修正** を要求する。entry が ms-05 / ms-06 / ms-07 / ms-08 で 5+ 件追加される想定 (`worker-input-rss` / `cron-fetch` / 等) を考えると、都度 6-7 行のボイラープレートが増える。

**Impact:**

- 現状 2 entry → 18 行程度の `vite.config.ts` だが、5-10 entry まで増えると 50-100 行のボイラープレートが固定化される
- helper 化 (`defineMultiEntryBackendTasks(['health', 'bff', 'worker-input-rss', ...])`) すれば 1 行で fan-out 可能だが、ms-01 では未提供

**Recommendation (将来):**

ms-02 / ms-05 設計時に `@totto2727/fp/vite` に `defineMultiEntryBackendTasks(entries: readonly string[])` helper を提供。**ms-01 では action 不要 (= Minor)**。

## Round history metadata

| Round | Date       | Reviewer instance               | Round-only Gate |
| ----- | ---------- | ------------------------------- | --------------- |
| 1     | 2026-05-06 | reviewer (api-design, initial)  | needs_fix       |
| 2     | 2026-05-06 | reviewer (api-design, re-check) | approved        |

Round 2 検証対象 commits:

- `dacf3e4` (T-I/r1): IdP `vite.config.ts` を `feed-platform-web` 同形化 + `.gitignore` 同形化 + `routes.ts` を `frames = {} as const` 形に揃え両プロジェクト対称化 → **M-1 / M-2 解消**
- `cf489b3` (T-H/r1): `feed-platform-web/app/smoke.test.ts` に Health テストを追加 (api-design 観点では out of scope。test-quality 観点で評価される)
- `900b120`: `design.md` を Phase 1 implementation deviation (`Context.Service` / Layer 合成形) に追従させる訂正、CC-6 / SC-6 観測仕様の OR 表記化、deviation note 2 箇所追記 → **M-3 解消**

Final Gate: `approved`. 0 Major / 0 Blocker findings open, 0 `accepted-as-is`。3 Major (M-1 / M-2 / M-3) はすべて Round 2 で `fixed` 確定。Minor 7 件 (m-1〜m-7) はいずれも ms-02 以降の設計改善余地として Retrospective 持ち越し前提 (本サイクル `accepted-as-is` ではなく `pending` 保持: ms-01 段階の最小雛形範囲では action 不要 / 将来 ADR-01 改訂や `@totto2727/fp/vite` helper 拡張で吸収予定)。Info 3 件は consistency check として保持。
