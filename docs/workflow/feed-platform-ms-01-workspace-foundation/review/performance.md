# Review Report: Performance

- **Cycle:** feed-platform-ms-01-workspace-foundation
- **Aspect:** performance
- **First reviewed:** 2026-05-06
- **Last updated:** 2026-05-06
- **Final Gate:** approved
- **Round count:** 1

## Summary

ms-01 は 3 プロジェクトすべてが Hello World レベル雛形であり、Cloudflare Workers cold start や Effect Layer 合成のオーバーヘッドはいずれも実用上無視できる範囲。**Blocker / Major は 0 件**。一方で **後続マイルストーン (ms-02 BetterAuth / ms-05 EventStore) で重い Service が Layer に追加された途端、現雛形の per-request ManagedRuntime 生成 + `Layer.unwrap` での Logger 動的判定が顕在化リスクになる**ため、その素地に対する Minor / Info の引き継ぎ事項を 7 件記録した。

主な観察:

- per-request `ManagedRuntime.make` + `await using` 方式は **`c.env` (Cloudflare bindings) を Service 注入する正当な選択肢**であり、Hello World レベルでは数十〜数百マイクロ秒オーダー (saas-example で実証済 — `research/effect-cloudflare-hono-integration.md:43-44, 101, 342-344`)。ms-01 では問題なし。
- `Layer.unwrap` + `Env.Service` 経由の Logger 形式判定は、`import.meta.env.PROD` 直参照より明確に追加コストを発生させるが **同じく Hello World レベルでは問題なし**。一方で **重い Service が同じ Layer に並ぶようになった ms-05 以降では、毎リクエストで `dynamicLoggerLayer` の Effect.gen + Layer.provideMerge 解決が走る**点が引き継ぎ Risk。
- backend の `setup:cloudflare:<entry>` fan-out は entry 数 N に対して N 回 `wrangler types` を直列実行する構造 (`vite.config.ts:24-31`)。ms-01 段階では 2 entry なので軽い (合計数秒) が、ms-05〜ms-08 で entry 数が 5〜10 に増えたとき CI 時間に効くことを記録。
- `observability.head_sampling_rate: 1` は全 Worker (3 プロジェクト × backend は 2 entry = 計 4 Worker) で **全リクエストサンプリング**。ms-01 段階のトラフィックなら quota 影響ゼロだが、本番化時に再考が必要な **明示的引き継ぎ点**。
- **identity-provider の `vite.config.ts` には `setup:cloudflare` task が欠落**しており、design.md C-4「`feed-platform-web` と完全同形」と乖離。これは perf 観点では「`worker-configuration.d.ts` がリポジトリ管理外で生成されない」リスクで、副次的に CI / build time に若干影響する可能性 → **m-3 で記録**。

## Findings list

| ID  | Severity | Finding                                                                                       | State             | First Round | Resolution commit | Notes                                                                                                                                         |
| --- | -------- | --------------------------------------------------------------------------------------------- | ----------------- | ----------- | ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| m-1 | Minor    | per-request `ManagedRuntime.make` の cumulative cost が ms-05 以降で問題化する余地            | pending (handoff) | 1           | -                 | ms-01 の Hello World では無視可能だが、重い Layer が増えると顕在化。引き継ぎ点は ms-05 / ms-06 設計時。詳細 → [m-1 detail](#m-1-detail)       |
| m-2 | Minor    | `Layer.unwrap` + `Env.Service` 経由の Logger 形式判定が毎リクエスト走る                       | pending (handoff) | 1           | -                 | static `import.meta.env.PROD` 直参照より遅いが ms-01 では無視範囲。ms-05 以降の負荷観察対象。詳細 → [m-2 detail](#m-2-detail)                 |
| m-3 | Minor    | `identity-provider/vite.config.ts:5-15` に `setup:cloudflare` task が欠落                     | pending           | 1           | -                 | design.md C-4 との乖離。`worker-configuration.d.ts` 生成が暗黙化し、CI で `wrangler types` が走らない可能性。詳細 → [m-3 detail](#m-3-detail) |
| i-1 | Info     | `observability.head_sampling_rate: 1` (全リクエストサンプリング) を 4 Worker 全部で固定       | accepted-as-is    | 1           | -                 | ms-01 トラフィックでは quota 影響ゼロ。本番化マイルストーン (ms-10 統合検証 or 別ロードマップ CI/CD) で再考                                   |
| i-2 | Info     | backend `setup:cloudflare:<entry>` fan-out が entry 数 N に対して直列 N 回 `wrangler types`   | accepted-as-is    | 1           | -                 | ms-01 (2 entry) では合計数秒。ms-05〜ms-08 で entry 5〜10 に増えた段階で並列化検討余地                                                        |
| i-3 | Info     | smoke test 1 件 / プロジェクトの実行時間は CI 全体で <1s 想定 (Effect 合成 + runPromise のみ) | accepted-as-is    | 1           | -                 | future bottleneck の素地としては最小。ms-05 以降で DB connection 込みの test を追加する際に再評価                                             |
| i-4 | Info     | `Logger.consolePretty()` (DEV) は Cloudflare Workers の構造化ログ前提と整合しない可能性       | accepted-as-is    | 1           | -                 | ms-01 ではローカル `wrangler dev` 利用前提のため問題なし。本番デプロイ時には `vars.ENV='production'` で `Logger.consoleJson` に切替済         |

## Detailed sections

### m-1 detail

**観察対象**: `js/app/feed-platform-backend/src/feature/runtime/server.ts:18-31` (および `feed-platform-web` / `identity-provider` の同形)、`js/app/feed-platform-backend/src/feature/runtime/hono.ts:13-20`。

**現状**: per-request middleware で `await using runtime = Runtime.make(c.env)` を毎リクエスト実行 → `ManagedRuntime.make(...)` で 3 Layer (`Health` / `Greeting` / `Env` + `dynamicLoggerLayer`) を合成。`research/effect-cloudflare-hono-integration.md:101, 342-344` の通り Cloudflare bindings (`c.env`) を Service として注入するためには **per-request パターンが必須**。これは正当な技術選択。

**ms-01 での影響**: Layer 合成のオーバーヘッドは数十マイクロ秒オーダー (saas-example で実証済)。Hello World では cold start (通常 < 5ms — design.md L1078) の中で完全に埋もれる。**現時点では問題なし**。

**ms-02 以降での Risk**: ms-05 (`feature/event-store/*`) / ms-02 (`feature/auth/jwt-verifier.ts` 等) で BetterAuth / Kysely / D1 connection 等が Layer に追加されると、毎リクエスト Layer 合成 → ManagedRuntime instance 化 → request 終了時に dispose の cycle が **重い処理を含むようになる** (saas-example が DB / BetterAuth Layer を持つ実例)。saas-example は同パターンで運用しており実用上耐えるが、Hello World では露呈しない隠れたコスト構造として **ms-05 設計時に「Service 単位で per-request か isolate-scoped かを再選別する」ことを推奨**。

**推奨アクション (ms-05 以降)**:

- `c.env` 依存の Service (= request-scoped 必須) と、stateless / connection pool 共有可能な Service (= isolate-scoped 可) を Layer 構造的に分離 (e.g. `Layer.provide(staticLayer)` を module top-level で 1 回構築 + per-request は env 依存分のみ)。
- `research/effect-cloudflare-hono-integration.md:43-44` で言及される module-top-level vs per-request のハイブリッド構造を ms-05 設計で検討。
- ms-01 での対応は不要 (=本サイクルでは accept、ただし引き継ぎとして **`docs/retrospective/<id>.md`** や **ms-05 milestone 設計時のチェックポイント**として伝達すべき)。

### m-2 detail

**観察対象**: `js/app/feed-platform-backend/src/feature/runtime/server.ts:11-16` (3 プロジェクトとも同形)。

```ts
const dynamicLoggerLayer = Layer.unwrap(
  Effect.gen(function* () {
    const env = yield* Env.Service
    return Logger.layer([env.ENV === 'production' ? Logger.consoleJson : Logger.consolePretty()])
  }),
)
```

**コスト構造**:

- **静的代替 (saas-example: `import.meta.env.PROD ? consoleJson : consolePretty()`)** は **Vite ビルド時に分岐が消える** (= 0 cost at runtime)。
- **採用形 (`Layer.unwrap` + `Env.Service` 経由)** は **毎リクエストで以下が走る**:
  1. `Layer.unwrap` 内側 Effect.gen の起動
  2. `yield* Env.Service` での Service 解決
  3. `env.ENV === 'production'` の文字列比較
  4. `Logger.layer([...])` の Layer 構築
  5. Layer.provide で挿入
- 各ステップは Effect の内部最適化で軽量 (合計でもマイクロ秒〜数十マイクロ秒オーダー想定)。Hello World では cold start に埋もれる。

**ms-01 での影響**: 観察上問題なし。design.md L206-211 の判断 (テスト容易性 / 設定の単一ソース化) が perf コストを上回る価値。

**ms-02 以降での Risk**: 重い処理が入った Layer 合成の **クリティカルパスに毎リクエスト含まれる**。Logger 形式という極めて頻度の低い切替判断のために、毎リクエスト Effect.gen + Service 解決を走らせるコスト構造は **判断頻度 vs 処理頻度のミスマッチ** (= "決まれば不変なものを毎回再計算する")。

**代替案 (ms-05 以降で再検討の余地、本サイクルでは採用案を維持)**:

- (案 R / design.md L1024 で fallback 候補として記載) `make(env)` 関数引数の `env.ENV` を直接見て **module load 時 1 回 / Worker boot 時 1 回 だけ** Logger Layer を構築し、以降のリクエストは構築済 Layer を共有する。`Layer.unwrap` を使わず `env.ENV === 'production' ? loggerJsonLayer : loggerPrettyLayer` を per-make で選ぶだけにする。テスト時は `Env.makeLayer({ ENV: 'production' })` を渡せばこの分岐に到達できるためテスト容易性も保たれる。
- ただし この変更は **ms-01 では overengineering**。重い Layer が並ぶ前段階での microoptimization は意味が薄い。

**推奨アクション**: ms-01 では現案を維持。ms-05 以降の Step 3 (Design) で「重い Layer の per-request 生成パターンが顕在化したら、Logger 部分のみ static 化を再検討」をチェックポイント化。

### m-3 detail

**観察対象**: `js/app/identity-provider/vite.config.ts:5-15`。

```ts
export default defineConfig({
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' }), cloudflare()],
  run: {
    tasks: {
      build: {
        command: 'vp build',
        input: [{ auto: true }, '!.wrangler/**', '!dist/**'],
      },
    },
  },
})
```

**乖離**: design.md C-4 (L795-797) は 「`feed-platform-web` と完全同形」と明記しているが、実装は `setup` / `setup:cloudflare` task が欠落 + `dependsOn: ['setup']` も欠落。`feed-platform-web/vite.config.ts:14-32` (= `setup:cloudflare` で `wrangler types` を呼ぶ + `build` が `dependsOn: ['setup']`) と比較すると差が明確。

**perf 観点での影響**:

- **CI ビルド時間**: identity-provider で `wrangler types` がスキップされる。`worker-configuration.d.ts` が事前生成されない場合、TypeScript チェック / Vite ビルド時に bindings 型が不正解になる可能性 → 失敗時のリトライコスト発生。
- **逆に成功する場合**: CI に `worker-configuration.d.ts` が commit 済 (= リポジトリ管理) で十分なら問題ないが、`identity-provider/.gitignore:1` を見ると 17 byte (おそらく `node_modules` のみ。`worker-configuration.d.ts` の扱いが他 2 プロジェクトと異なる) — **暗黙の挙動依存になっている**。
- **build time 比較**: identity-provider は backend / web より「先に走る」 / 「並列に走る」と Vite+ cache hit 構造が乱れる可能性。task 定義が他プロジェクトと不揃いだと `vp run -r build` の依存解決が予期せぬ順序になる。

**recommended fix**: identity-provider の `vite.config.ts` を `feed-platform-web` と完全に揃える (design.md C-4 の意図通り)。これは perf より consistency 観点だが、**build / CI のキャッシュ効率と再現性** に直接影響する Minor。

```ts
// 推奨修正案 (feed-platform-web と完全同形)
import { cloudflare } from '@cloudflare/vite-plugin'
import { defineTaskInputFromOutput } from '@totto2727/fp/vite'
import { remix } from 'vite-plugin-remix'
import { defineConfig } from 'vite-plus'

const taskInput = defineTaskInputFromOutput({
  setup: {
    cloudflare: ['.wrangler/**', 'worker-configuration.d.ts'],
  },
})

export default defineConfig({
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' }), cloudflare()],
  run: {
    tasks: {
      build: {
        command: 'vp build',
        dependsOn: ['setup'],
        input: taskInput.build,
      },
      setup: {
        command: '',
        dependsOn: ['setup:cloudflare'],
      },
      'setup:cloudflare': {
        command: 'wrangler types',
        input: taskInput.setup.cloudflare,
      },
    },
  },
})
```

**Severity 判定**: perf 観点単独では Major にしない (= ms-01 の build 全体時間が極端に伸びることはない)。一方で readability / api-design 観点では Major 相当 (3 プロジェクト同形のはずが 1 つだけ乖離) なので、**holistic / readability viewpoint の reviewer で同 finding が上がる可能性が高い**ことを記録。perf 視点では Minor として扱い、修正は他観点の Major に従って合流すれば足りる。

## Open questions

1. **ms-05 / ms-06 設計時に重い Layer を per-request で構築し続けるかの再検討**: 現雛形は saas-example 準拠で per-request を全面採用しているが、Service 単位で `staticLayer` (module top-level 1 回構築) と `requestLayer` (per-request) を分離する設計が将来必要かを ms-05 milestone Step 3 で評価する。本 ms-01 での対応は不要。

2. **`head_sampling_rate: 1` の本番運用方針**: ms-01 では全 4 Worker (backend × 2 entry + web + identity-provider) で全リクエストサンプリング固定。Cloudflare Workers の Logs cost / Tail Workers quota は本番トラフィック量によっては無視できない金額になる。本サイクルでは accept (= 開発段階の観測性最大化) するが、本番化時の sampling rate 調整方針 (例: 0.1 = 10%) を CI/CD 別ロードマップで決める必要あり。

3. **`Logger.consolePretty({ mode: 'tty' })` Cloudflare Workers での動作**: `consolePretty` は ANSI escape を含む装飾出力 (`node_modules/.pnpm/effect@4.0.0-beta.60/.../Logger.d.ts:565-580` 参照、`mode: 'tty' | 'browser' | 'auto'` オプションあり) で、Cloudflare Workers の本番ログには TTY 検出が無効化されるため auto モードで `browser` が選択される可能性が高い (= ANSI 装飾なしで JSON 化されない普通の console.log)。**ms-01 では `vars.ENV='development'` 固定 + 本番では `'production'` で `Logger.consoleJson` に切替する設計のため問題ないが、誤って `vars.ENV` を切り替え忘れた場合に本番で `consolePretty` が動作してログが構造化されない**。**設計判断 (m-2 で記録) で `wrangler.jsonc.vars.ENV` が単一ソース化されている点が運用安全性の決め手**。ms-02 以降の deploy 自動化では「PROD env で `vars.ENV='production'` を強制する CI guard」を検討。

## Round history metadata

| Round | Date       | Reviewer instance    | Round-only Gate |
| ----- | ---------- | -------------------- | --------------- |
| 1     | 2026-05-06 | reviewer/performance | approved        |

Final Gate: `approved`. 0 Major / Blocker findings open, 4 `accepted-as-is`, 3 `pending (handoff)` (m-1 / m-2 はいずれも本ms-01 で対応不要、m-3 は他観点の Major 合流前提)。

<!--
Authoring guide: share-artifacts/references/review-report.md
-->
