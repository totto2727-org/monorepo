# Research Note: Effect + Cloudflare Workers + Hono の最小統合パターン

- **Identifier:** feed-platform-ms-01-workspace-foundation
- **Topic:** effect-cloudflare-hono-integration
- **Researcher:** researcher-effect-cloudflare-hono
- **Created at:** 2026-05-04
- **Scope:** SC-6 を満たすため、3 プロジェクト (`feed-platform-backend` / `feed-platform-web` / `identity-provider`) に共通する **`effect-layer` / `effect-runtime` / `effect-hono` ↔ Cloudflare Workers** の最小統合パターン (Service / Layer / ManagedRuntime / Hono Middleware の接続) を確定する。

## Subject of investigation

本 Research Note は **Effect Layer / ManagedRuntime / Hono が Cloudflare Workers `fetch` ハンドラ上でどう連携するか**の単一視点に絞る。具体的には Intent Spec SC-6「各プロジェクトに `effect-layer` / `effect-runtime` パターンを使った Service 定義例が 1 件以上含まれる」を満たす最小コード例を、3 プロジェクト (`feed-platform-backend` 純 Worker / `feed-platform-web` Remix-Worker / `identity-provider` Remix-Worker + DB binding) ごとに提示する。

スコープ外 (他 Researcher 担当):

- wrangler のマルチエントリ構造詳細 (entry point ごとの `worker.ts` + `wrangler.jsonc` ペア配置パターン)
- Vite+ task 規約 (`run.tasks` の各タスクパラメータ詳細)
- `hono-remix-v3-cloudflare-example` のディレクトリ構造詳細 (`controllers/` / `ui/` / `assets/` 等)
- 認証認可フロー実装 (ms-02 以降責務)

## Findings

### F1. 既存スキル `effect-layer` の最小 Service 定義パターン

- **Service 定義は `ServiceMap.Service<Instance>('@app/<app-name>/feature/<name>/Service')` 形式**で固定 (cf. `.claude/skills/effect-layer/SKILL.md` "Service Tag Format" 節)
- **Layer 構築子の使い分け** (cf. SKILL.md "Layer Constructors" 節):
  - `Layer.succeed` — 静的値 (env / 設定オブジェクト等)。例: `Layer.succeed(Env.Service, env)` (`js/app/saas-example/src/feature/env.ts:17`)
  - `Layer.sync` — 同期コンストラクタ (依存なし)。例: `localLayer = Layer.sync(Service, () => makeInMemory())` (`js/app/saas-example/src/feature/db/kysely.ts:36`)
  - `Layer.effect` — 1 つ以上の依存 Service を `Effect.gen` 内で `yield*` して取得して構築 (`js/app/saas-example/src/feature/db/kysely.ts:38-44`、`js/app/saas-example/src/feature/auth/better-auth.ts:60-67`)
- **export 規約**: `Instance` 型 / `Service` tag / `layer` (or `localLayer` / `remoteLayer` 等) のみ export。`make*` 関数 / 内部ヘルパは非 export
- **Service 利用は `Effect.gen` 内 `yield* SomeModule.Service`** で取得 (cf. SKILL.md "Service Access" 節)

### F2. 既存スキル `effect-runtime` の Cloudflare Workers での組み合わせ

- **`ManagedRuntime.make(composedLayer)`** で全 Service を所有する runtime を作成 (cf. `.claude/skills/effect-runtime/SKILL.md`)
- **`Layer.provideMerge` vs `Layer.provide`** の使い分け:
  - `provideMerge` — 提供 + 下流から両 Layer の Service を可視化 (DB / Env を Hono ハンドラから直接 `yield*` したい場合)
  - `provide` — 提供のみ (内部依存 = Logger / Tracing 等の隠蔽)
  - 実例: `js/app/saas-example/src/feature/runtime/server.ts:7-16` で `BetterAuth.layer.pipe(Layer.provideMerge(DB.remoteLayer), Layer.provideMerge(Env.makeLayer(env)), Layer.provide(Logger.layer([Logger.consoleJson])))`
- **`DisposableRuntime` (`Symbol.asyncDispose`) パターン**は **`await using` を Hono middleware 内で使い、リクエスト終了時に `dispose()` する**ことで request-scoped lifecycle を実現 (`js/app/saas-example/src/feature/runtime/hono.ts:5-12`)
- **環境別 runtime 切り替え**: `import.meta.env.PROD` で `consoleJson` / `consolePretty` を切替 (`js/app/saas-example/src/feature/runtime/server.ts:55-56`)
- **Cloudflare bindings (`env: KV / D1 / Secrets`) を Service として注入する形**は `Env.Type` を `Layer.succeed(Env.Service, env)` で渡す既存パターンに準拠 (`saas-example/src/feature/env.ts` が `BETTER_AUTH_*` / `DATABASE_*` を `interface Type` でまとめている)。Cloudflare では `c.env` 経由で Worker `fetch(request, env, ctx)` の `env` を取得し、middleware で runtime に渡す (`js/app/saas-example/src/feature/runtime/hono.ts:7` の `c.env`)
- **runtime の生成位置**:
  - **module top-level**: `js/app/rss-graphql/app/app.ts:12` のように `const runtime = ManagedRuntime.make(...)` を module top-level で 1 回生成し全リクエストで共有 (= isolate-scoped runtime)。Service が isolate ごとに 1 個で済む場合に有効 (DB connection pool 等)
  - **per-request**: `saas-example` のように `await using runtime = makeRuntime(c.env)` を middleware 内で呼んで request 終了時に dispose (= request-scoped runtime)。`c.env` (Cloudflare bindings) 依存の Service がある場合に必要

### F3. 既存スキル `effect-hono` の Middleware / Handler パターン

- **`factory.createMiddleware` で runtime を `c.var` に注入**する形が公式パターン (`js/app/saas-example/src/feature/runtime/hono.ts:5-12`)
- **`Hono Env.Variables.runtime: Runtime` を context 型に登録**して `c.var.runtime.runPromise(...)` を全ハンドラで利用 (`js/app/saas-example/src/feature/share/lib/hono/context.ts:8-17`)
- **handler / middleware 共通の二段構え**:
  1. `program = Effect.gen(function* () { ... })` でビジネスロジック
  2. `programWithCatch = program.pipe(Effect.tapError(logError), Effect.catchTags({ ... }))` で HTTP マッピング
  3. `c.var.runtime.runPromise(programWithCatch)` で実行
  - 実例: `js/app/saas-example/src/feature/auth/middleware.ts:7-32`
- **`Data.TaggedError('http/error/<Name>')` + `makeResponseEffect()` で HTTP エラーを定義** (`js/app/saas-example/src/feature/http/error.ts`)
- **`runPromise` / `runFork` の使い分け**: スキル中で明示されているのは `runPromise` のみ (Hono が `Promise<Response>` を期待するため)。`runFork` は Cloudflare Workers の `ctx.waitUntil(...)` パターン (バックグラウンドジョブ) で使うが、ms-01 では未使用
- **middleware 順序固定**: `contextStorage()` (最初) → runtime middleware → `logger()` → ルート別 sub-app (`js/app/saas-example/src/entry.hono.ts:11-20`)
- **Hono `factory` は `createFactory<Env>()` で型付き**生成 (`js/app/saas-example/src/feature/share/lib/hono/factory.ts:5`)

### F4. `hono-remix-v3-cloudflare-example` の Effect 利用状況

- **DI / Runtime としては Effect を利用していない** — `app/ui/todo.client.tsx:1` で `Array, Predicate, String` を utility namespace として使用するのみ (`grep -rn "from 'effect'"` 結果)
- `package.json` には `effect: catalog:effect` 依存があるが、SSR / Worker 側の Service 定義 / Layer / ManagedRuntime は皆無
- = **Remix-Worker パターンの Effect 統合参照実装は `hono-remix-v3-cloudflare-example` には存在しない**。`js/app/saas-example/` (TanStack Start + Hono mount) と `js/app/rss-graphql/` (純 Hono Worker + ManagedRuntime) を参考にする必要がある

### F5. `rss-graphql` (純 Worker + Hono + Effect) の最小例

`js/app/rss-graphql/app/app.ts:12` の以下が **「Cloudflare Workers + Hono + Effect」純 Worker パターンの最小実証**:

```typescript
const runtime = ManagedRuntime.make(FetchHttpClient.layer)

interface AppEnv {
  Variables: { runtime: typeof runtime }
}

const app = new Hono<AppEnv>().use(async (c, next) => {
  c.set('runtime', runtime)
  await next()
})
// ... routes that use c.var.runtime.runPromise(...)
```

= **module top-level で `ManagedRuntime.make` を 1 回呼ぶ最小形**。`c.env` を取らず Cloudflare bindings なしで成立する場合の最短ルート。ただし Cloudflare bindings (KV / D1 / Secrets) を注入したい場合は `await using` per-request 方式 (saas-example) が必要。

### F6. `saas-example` (Remix 系 + Hono mount + Effect) の最小例

`js/app/saas-example/src/entry.worker.ts:14` の以下が **「Cloudflare Workers + Hono + Remix 系 (TanStack Start) + Effect」最小実証**:

```typescript
const hono = makeHono(Runtime.make).mount('/', tanstackStart)
export default hono
```

= **Hono を最外層 entry とし、Remix 系 framework は `mount('/', ...)` で Hono の sub-handler として組み込む**。Hono middleware が先に走るため Effect runtime の注入が SSR (`loader` / `action`) 実行前に完了する。

### F7. Cloudflare bindings を Effect Service として注入するパターン

- **bindings interface を `Env.Type` として宣言**し、`Layer.succeed(Env.Service, env)` でリクエストの `c.env` を渡す (`saas-example/src/feature/env.ts:13-17`)
- bindings の中の特定キー (例: `KV` / `D1`) を細粒度な Service として切り出したい場合は、`Layer.effect(KvService, Effect.gen(function* () { const env = yield* Env.Service; return env.MY_KV }))` 相当を書く (= `saas-example/src/feature/db/kysely.ts:38-44` の `remoteLayer` と同型のパターン)
- **構造的に重要**: `Env` Service は **request-scoped**でなければならない (`c.env` がリクエストごとに変わるため)。よって module top-level の `ManagedRuntime.make` ではなく、middleware 内で `makeRuntime(c.env)` を呼ぶ per-request パターンが標準

### F8. Remix v3 (`feed-platform-web` / `identity-provider`) ↔ 純 Worker (`feed-platform-backend`) の差

`hono-remix-v3-cloudflare-example/app/entry.worker.ts` のパターンは **`import app from './app.tsx'; export default app`** (Hono app 自体を export)。Remix の `loader` / `action` は **Hono の context (`c.var.runtime`) を `hono/context-storage` 経由で取得**する形が saas-example の方式 (`feature/share/lib/hono/context.ts:19` の `getContextFromALC<Env>()`)。

→ **差は「Effect runtime の注入位置と取得方法」のみ**:

| 項目                      | 純 Worker (`feed-platform-backend`)                   | Remix-Worker (`feed-platform-web` / `identity-provider`)                                        |
| ------------------------- | ----------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| entry                     | `worker.ts` で `export default { fetch }` or Hono app | `app/entry.worker.ts` で `export default app` (Hono app)                                        |
| runtime 生成位置          | Hono middleware (per-request) or module top-level     | Hono middleware (per-request)                                                                   |
| ハンドラから runtime 取得 | `c.var.runtime`                                       | `c.var.runtime` (Hono handler) or `getContext().var.runtime` (Remix `loader` / `action` 内 ALC) |
| 必要 middleware           | `contextStorage()` + runtime middleware               | `contextStorage()` + runtime middleware (Remix mount より前)                                    |
| Cloudflare bindings       | `c.env` から取得                                      | `c.env` から取得                                                                                |

### F9. `@totto2727/fp` の利用例 (ms-01 雛形に含めるべきか)

- **主要 export** (`.claude/skills/totto2727-fp/SKILL.md` "Exported Paths" 節):
  - `./effect/cuid` — CUID Generator (`Generator.layer` を Layer 合成で利用可)
  - `./effect/util` — `EffectFnSuccess` / `nonEmptyArrayOrNone` / `tap` 等の Effect 型ヘルパ
  - `./effect/option-t` / `./option-t/effect` — Effect Exit ↔ option-t Result ブリッジ
  - `./vite` — Vite+ `defineTaskInputFromOutput` (`saas-example/vite.config.ts:6, 10` で利用)
  - `./tsconfig/vite` — Vite 用 tsconfig preset
- **既存 monorepo 全体での利用密度が高い** — `saas-example/package.json` `hono-remix-v3-cloudflare-example/package.json` `rss-graphql/package.json` 全てで `@totto2727/fp: workspace:*` を devDependencies に持つ
- **ms-01 雛形に含めるべきか**: **3 プロジェクトとも `devDependencies` に追加する**ことを強く推奨。理由は (1) `vite.config.ts` 内 `defineTaskInputFromOutput` を使うのが既存規約、(2) Service 例で CUID / Effect ヘルパを使う場合に追加変更不要、(3) tsconfig preset (`./tsconfig/vite`) を `extends` するのが既存スタイル

## Sources

- 必須読み物:
  - `docs/workflow/feed-platform-ms-01-workspace-foundation/intent-spec.md:69` (SC-6 = `effect-layer` / `effect-runtime` / `ManagedRuntime` のいずれかを使う TS ファイル必須)
  - `docs/roadmap/feed-platform/roadmap.md:76` (規範: `effect-layer` / `effect-runtime` / `effect-hono` パターン優先)
  - `docs/roadmap/feed-platform/milestones/ms-01-workspace-foundation.md:21` (横断ユーティリティ層の使い方を雛形上で例示)
- スキル本体:
  - `.claude/skills/effect-layer/SKILL.md` (Service tag / Layer 構築子 / 命名規約)
  - `.claude/skills/effect-runtime/SKILL.md` (Layer 合成 / ManagedRuntime / DisposableRuntime / 環境別 runtime)
  - `.claude/skills/effect-hono/SKILL.md` (`factory.createMiddleware` / `Effect.gen` + `catchTags` / `runPromise` / `Data.TaggedError`)
  - `.claude/skills/totto2727-fp/SKILL.md` (`./vite` / `./effect/*` / `./tsconfig/vite`)
- 参照実装 (`js/app/saas-example/`):
  - `src/feature/env.ts:13-17` (Cloudflare bindings の Service 化)
  - `src/feature/db/kysely.ts:34-44` (`Layer.sync` / `Layer.effect` 1 依存)
  - `src/feature/auth/better-auth.ts:58-67` (`Layer.effect` 2 依存)
  - `src/feature/runtime/server.ts:1-58` (Layer 合成 + ManagedRuntime + DisposableRuntime + 環境別 runtime)
  - `src/feature/runtime/hono.ts:5-12` (`await using` middleware = request-scoped runtime)
  - `src/feature/share/lib/hono/factory.ts:5` (`createFactory<Env>()`)
  - `src/feature/share/lib/hono/context.ts:8-19` (Hono Env 型 + `hono/context-storage` 経由の取得)
  - `src/feature/http/error.ts:8-36` (`Data.TaggedError('http/error/<Name>')` + `makeResponseEffect()`)
  - `src/feature/auth/middleware.ts:7-50` (二段構え: `program` + `programWithCatch` + `c.var.runtime.runPromise`)
  - `src/feature/auth/app.ts:6-11` (sub-app handler パターン)
  - `src/entry.hono.ts:1-22` (middleware 順序: `contextStorage()` → runtime → `logger()` → routes)
  - `src/entry.worker.ts:1-16` (Hono を最外層 entry にして Remix 系を `mount('/', ...)`)
  - `vite.config.ts:6-67` (Vite+ task 規約 = `setup` / `build` / `defineTaskInputFromOutput`)
  - `wrangler.jsonc` (`compatibility_flags: ["nodejs_compat"]` / `placement: "smart"`)
- 参照実装 (`js/app/rss-graphql/`):
  - `app/app.ts:1-55` (純 Worker + Hono + module-top-level `ManagedRuntime.make` 最小例)
  - `app/entry.worker.ts:1-3` (Hono app をそのまま export)
  - `app/feature/hono/context.ts:1-13` (Variables.runtime のみの最小 Hono Env 型)
  - `app/feature/graphql/rss-fetch-client.ts:1-13` (Effect.gen 内で `HttpClient` Service を `yield*`)
- 参照実装 (`js/app/hono-remix-v3-cloudflare-example/`):
  - `app/entry.worker.ts:1-3` (`import app from './app.tsx'; export default app`)
  - `wrangler.jsonc:1-20` (`assets.directory: ./dist/client` / `binding: ASSETS` / `not_found_handling: none`)
  - `package.json:13-25` (`effect` / `hono` / `remix` / `hono-remix-middleware` / `vite-plugin-remix` / `@totto2727/fp` 依存)
  - `CLAUDE.md` (`app/entry.worker.ts` → `app/app.ts` → `controllers/<x>.tsx` の owner 配置パターン)

## Implications for design

ms-01 では **3 プロジェクト全部に同じ "Effect skeleton" を 1 ファイル単位でコピペできる構造**にし、後続マイルストーンで feature を肉付けできる粒度を確保する。以下、Step 3 (Design) で `architect` がそのまま採用できる粒度で記述する。

### I-1. 3 プロジェクト共通の最小 Service 例 (= SC-6 を満たす最小コード)

各プロジェクトに以下 5 ファイルを置けば SC-6 を満たす:

1. `<project>/src/feature/env.ts` — Cloudflare bindings の Service 化 (依存なし、`Layer.succeed`)
2. `<project>/src/feature/clock.ts` (もしくは類似の依存なし Service。例: HelloWorld 値プロバイダ) — 1 依存ナシ Service (`Layer.sync`)
3. `<project>/src/feature/runtime/server.ts` — Layer 合成 + ManagedRuntime + DisposableRuntime
4. `<project>/src/feature/runtime/hono.ts` — `await using` middleware
5. `<project>/src/feature/share/lib/hono/{factory,context}.ts` — Hono `factory` + Env 型

これだけで `Layer.succeed` (依存なし) + `Layer.sync` (依存なし計算) + `Layer.effect` (Env 依存) の 3 段階全てが揃い、`ManagedRuntime` + `Hono middleware` 経由で `c.var.runtime.runPromise(...)` が走る最小形が成立する。

### I-2. 純 Worker (`feed-platform-backend`) の seed: `src/health/worker.ts`

Intent Spec (`SC-5`) の「entry point ごとに `worker.ts` + `wrangler.jsonc` のペア配置」に合わせ、最低 2 entry ある中の 1 つを以下のシード `worker.ts` にする (もう 1 つは別 Researcher の責務で別 entry の最小実装):

```typescript
// js/app/feed-platform-backend/src/health/worker.ts
import { Effect, Layer, Logger, ManagedRuntime, ServiceMap } from 'effect'
import { Hono } from 'hono'
import { contextStorage } from 'hono/context-storage'

// --- Env Service (Cloudflare bindings) ---
export interface EnvType {
  ENV: 'production' | 'development'
}
export const EnvService = ServiceMap.Service<EnvType>('@app/feed-platform-backend/feature/env/Service')
export const makeEnvLayer = (env: EnvType) => Layer.succeed(EnvService, env)

// --- Greeting Service (依存なし、Layer.sync) ---
export interface GreetingType {
  greet: (name: string) => string
}
export const GreetingService = ServiceMap.Service<GreetingType>('@app/feed-platform-backend/feature/greeting/Service')
export const greetingLayer = Layer.sync(GreetingService, () => ({
  greet: (name) => `Hello, ${name}`,
}))

// --- HealthChecker Service (1 依存: Env、Layer.effect) ---
export interface HealthCheckerType {
  check: () => Effect.Effect<{ status: 'ok'; env: string }>
}
export const HealthCheckerService = ServiceMap.Service<HealthCheckerType>(
  '@app/feed-platform-backend/feature/health/Service',
)
export const healthCheckerLayer = Layer.effect(
  HealthCheckerService,
  Effect.gen(function* () {
    const env = yield* EnvService
    return { check: () => Effect.succeed({ status: 'ok', env: env.ENV }) }
  }),
)

// --- Runtime ---
const makeRuntime = (env: EnvType) =>
  ManagedRuntime.make(
    healthCheckerLayer.pipe(
      Layer.provideMerge(greetingLayer),
      Layer.provideMerge(makeEnvLayer(env)),
      Layer.provide(Logger.layer([Logger.consoleJson])),
    ),
  )
type Runtime = ReturnType<typeof makeRuntime>

// --- Hono app ---
interface AppEnv {
  Bindings: EnvType
  Variables: { runtime: Runtime }
}

const app = new Hono<AppEnv>()
  .use(contextStorage())
  .use(async (c, next) => {
    const runtime = makeRuntime(c.env)
    c.set('runtime', runtime)
    try {
      await next()
    } finally {
      await runtime.dispose()
    }
  })
  .get('/health', (c) => {
    const program = Effect.gen(function* () {
      const checker = yield* HealthCheckerService
      const result = yield* checker.check()
      return c.json(result)
    })
    return c.var.runtime.runPromise(program)
  })

export default app
```

ペアの `wrangler.jsonc` (entry ごと):

```jsonc
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "feed-platform-backend-health",
  "main": "./src/health/worker.ts",
  "compatibility_date": "2026-02-01",
  "compatibility_flags": ["nodejs_compat"],
  "vars": { "ENV": "development" },
}
```

### I-3. Remix-Worker (`feed-platform-web`) の seed: `app/entry.worker.ts` + `app/app.ts` 相当

`hono-remix-v3-cloudflare-example` を踏襲し、Hono app を最外層 entry にして Remix を `mount` する。Effect Service 例は I-2 と同型の `app/feature/{env,greeting,health}.ts` + `app/feature/runtime/{server,hono}.ts` を用意し、`app/app.tsx` で middleware に組み込む:

```typescript
// js/app/feed-platform-web/app/app.tsx (簡略化)
import { Hono } from 'hono'
import { contextStorage } from 'hono/context-storage'
import { logger } from 'hono/logger'

import * as RuntimeHonoAdapter from './feature/runtime/hono.ts'
import * as Runtime from './feature/runtime/server.ts'
import { factory } from './feature/share/lib/hono/factory.ts'
// (Remix v3 mount は hono-remix-v3-cloudflare-example の方式を踏襲)

const app = factory
  .createApp()
  .use(contextStorage())
  .use(RuntimeHonoAdapter.makeMiddleware(Runtime.make))
  .use(logger())
  .get('/api/v1/hello', (c) => {
    const program = Effect.gen(function* () {
      const greeting = yield* GreetingService
      return c.json({ message: greeting.greet('feed-platform-web') })
    })
    return c.var.runtime.runPromise(program)
  })
// ... Remix の routes は別 Researcher 責務 (`app/routes.ts` 経由)

export default app
```

```typescript
// js/app/feed-platform-web/app/entry.worker.ts
import app from './app.tsx'
export default app
```

`feature/runtime/server.ts` / `feature/runtime/hono.ts` / `feature/share/lib/hono/{factory,context}.ts` は **`saas-example/src/feature/runtime/*` と同形**でコピー (BetterAuth.layer を抜き、I-2 の `healthCheckerLayer` に相当する Service を 1 個追加するのみ)。

### I-4. Remix-Worker (`identity-provider`) の seed: I-3 + DB binding 設定追加

ms-01 では DB を実際に使わないが「DB 設定を後で追加できる構造」を示すため、**`feature/db/` ディレクトリだけ作成し空の placeholder Service** (= `saas-example/src/feature/db/kysely.ts:36` の `localLayer` 相当の `Layer.sync(Service, () => ({}))`) を用意する案もある。ただし ms-01 完了条件 (SC-6) は Service 1 件で満たされるため、**雛形では I-3 と同型に留めて DB は ms-02 以降で追加**するのが YAGNI 的に妥当。

`wrangler.jsonc` には ms-02 以降で DB binding を追加する想定の箇所を **コメントで明示**しておく:

```jsonc
{
  "name": "identity-provider",
  "main": "./app/entry.worker.ts",
  "compatibility_date": "2026-02-01",
  "compatibility_flags": ["nodejs_compat"],
  // ms-02 以降で D1 / KV / Secrets binding を追加する
  // "d1_databases": [{ "binding": "DB", "database_name": "...", "database_id": "..." }],
  "assets": { "directory": "./dist/client", "binding": "ASSETS", "not_found_handling": "none" },
}
```

### I-5. 純 Worker と Remix-Worker の差を Step 3 design.md でどう表現するか

**「Effect runtime の注入機構自体は同型 (Hono middleware + `ManagedRuntime` + `await using`)、差は entry の export 形と Remix mount の有無のみ」**として記述。具体的には:

- 共通: `feature/runtime/{server,hono}.ts` / `feature/share/lib/hono/{factory,context}.ts` / `feature/env.ts` の 5 ファイルが 3 プロジェクトともほぼ同型
- 差分: `entry.worker.ts` の export 内容
  - `feed-platform-backend`: `export default { fetch: app.fetch }` または `export default app` (Hono app 直 export)
  - `feed-platform-web` / `identity-provider`: `import app from './app.tsx'; export default app` (Remix 系統合済み Hono app を再 export)

### I-6. Cloudflare bindings 注入は per-request 必須

`module-top-level ManagedRuntime` (rss-graphql 方式) は Cloudflare bindings なしの場合のみ許容。3 プロジェクトとも env / 将来の DB binding を扱う想定なので **`saas-example` の `await using` per-request パターンを採用**する。`feed-platform-backend` の各 worker entry も同パターン (I-2 で実証)。

### I-7. `@totto2727/fp` を 3 プロジェクトとも `devDependencies` に追加

理由は F9 の通り。`vite.config.ts` の `defineTaskInputFromOutput` 利用と tsconfig preset (`./tsconfig/vite`) 利用が既存規約。雛形作成時に追加し忘れると Step 6 で後付け修正が発生する。

### I-8. `Data.TaggedError` + `catchTags` パターンを ms-01 で採用するか

SC-6 の最小要件は「Layer / Service / ManagedRuntime のいずれかを使う TS ファイルが存在」のみ。HTTP error マッピングまでは要求されていない。ただし **3 プロジェクトとも `feature/http/error.ts` を `saas-example/src/feature/http/error.ts` のコピーで配置しておく**ことを推奨 (理由: ms-02 以降で必ず使う + コピー 1 ファイルなのでコスト極小 + Service 例ハンドラで `catchTags({ UnknownError: ... })` を書く際にすでに必要)。

## Remaining unknowns

- **U1. `feed-platform-backend` の worker entry を最低 2 件にする際、2 件目 entry は何を置くか** — Intent Spec SC-5 は「entry が 2 件以上」を要求するが、具体的に何を 2 件目にするかは決まっていない。本 Researcher の viewpoint 外 (wrangler 多 entry 配置を担当する別 Researcher 責務)。Step 3 design.md でどちらの Researcher の結論を採用するか Main の判定が必要
- **U2. `feed-platform-web` / `identity-provider` で Remix `loader` / `action` から `c.var.runtime` を取得する具体的書き方** — `saas-example` の方式 (`hono/context-storage` + `getContext().var.runtime`) を踏襲する想定だが、`hono-remix-v3-cloudflare-example` の Remix v3 (`createStartHandler` ではなく `remix` パッケージ直接) ではマウント機構が異なる可能性。Step 3 で `architect` が `hono-remix-middleware` (`js/package/hono-remix-middleware/`) の API を確認する必要あり (本 Researcher 範囲外)
- **U3. Vitest の Effect テストパターン** — SC-3 の smoke test 1 件は何を書くか。`Effect.runSync` / `Layer.merge` でテスト用 layer を作る既存パターンが saas-example にあるかは未調査。Step 4 (QA Design) の `qa-analyst` 責務に委譲
- **U4. `Logger.layer([Logger.consoleJson])` を ms-01 で採用するか** — saas-example は採用しているが、ms-01 雛形で必須ではない。3 プロジェクト共通の規約として Step 3 で確定推奨

## References

すべて本リポジトリ内の絶対パス。skill SKILL.md 引用は本文中の `Findings` セクションを参照。

- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/.claude/skills/effect-layer/SKILL.md`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/.claude/skills/effect-runtime/SKILL.md`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/.claude/skills/effect-hono/SKILL.md`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/.claude/skills/totto2727-fp/SKILL.md`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/saas-example/src/feature/env.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/saas-example/src/feature/db/kysely.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/saas-example/src/feature/auth/better-auth.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/saas-example/src/feature/auth/middleware.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/saas-example/src/feature/auth/app.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/saas-example/src/feature/runtime/server.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/saas-example/src/feature/runtime/hono.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/saas-example/src/feature/share/lib/hono/factory.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/saas-example/src/feature/share/lib/hono/context.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/saas-example/src/feature/http/error.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/saas-example/src/entry.hono.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/saas-example/src/entry.worker.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/saas-example/vite.config.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/saas-example/wrangler.jsonc`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/rss-graphql/app/app.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/rss-graphql/app/entry.worker.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/rss-graphql/app/feature/hono/context.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/rss-graphql/app/feature/graphql/rss-fetch-client.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/rss-graphql/wrangler.jsonc`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/hono-remix-v3-cloudflare-example/app/entry.worker.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/hono-remix-v3-cloudflare-example/wrangler.jsonc`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/app/hono-remix-v3-cloudflare-example/CLAUDE.md`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/fp/src/effect/util.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/fp/src/effect/cuid.ts`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/docs/workflow/feed-platform-ms-01-workspace-foundation/intent-spec.md`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/docs/roadmap/feed-platform/roadmap.md`
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/docs/roadmap/feed-platform/milestones/ms-01-workspace-foundation.md`
