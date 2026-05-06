# Review Report: Holistic (整合性 / Task Plan 完了 / SC 充足見通し)

- **Cycle:** feed-platform-ms-01-workspace-foundation
- **Aspect:** holistic — 整合性 / Task Plan 完了判断 / design.md 整合 / Intent Spec SC 充足見通し / 明らかなバグの早期検出
- **First reviewed:** 2026-05-06
- **Last updated:** 2026-05-06
- **Final Gate:** needs_fix
- **Round count:** 1

## Findings list

| ID  | Severity | Finding                                                                                                                                                                                                                                                                                                               | State                       | First Round | Resolution commit | Notes                                                                                                                                                                                                                                                                                                                                                                                         |
| --- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------- | ----------- | ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| M-1 | Major    | `js/app/identity-provider/vite.config.ts` に `setup:cloudflare` (= `wrangler types`) task が **未定義**。design.md L797 / C-4 が「`feed-platform-web` と完全同形」を明示し、design.md L31 / SC-9 整合性表 (L1158) も同 task の存在を前提にしている。                                                                  | pending                     | 1           | -                 | 詳細は [detail](#m-1-detail-identity-provider-viteconfigts-に-setupcloudflare-task-が欠落). Step 8 (Validation) で TC-024 (CI) と build/setup の依存関係が暫定 PASS 状態だが、SC-9「`vite.config.ts` の存在」字面は満たすため Blocker ではない。Step 9 (Retrospective) で扱うか修正かを Main / user に判断要請。                                                                              |
| m-1 | Minor    | `js/app/identity-provider/.gitignore` に `worker-configuration.d.ts` が記載されておらず `feed-platform-web/.gitignore:3` と divergent。`wrangler types` 実行時に未追跡の生成ファイルが worktree に残る可能性。                                                                                                        | pending                     | 1           | -                 | 現状 IdP には `worker-configuration.d.ts` が存在しないため実害ゼロだが、ms-02 で `wrangler types` を走らせた際に git ノイズになる。M-1 と合わせて修正推奨。                                                                                                                                                                                                                                   |
| m-2 | Minor    | `js/app/identity-provider/app/routes.ts:13-15` で `frames = { content: 'content' } as const` のまま (例テンプレートの残骸)。`feed-platform-web/app/routes.ts:13` は `frames = {} as const` に整理済で、3 プロジェクト雛形整備の対称性が崩れている。                                                                   | pending                     | 1           | -                 | TC-022 観測仕様 (`grep -E 'createPageOrFrame'` against `app/app.tsx`) は両プロジェクト 0 件で PASS のため SC-9 違反ではない。`frames.content` は誰も import / 使用していない dead code。Step 9 改善候補。                                                                                                                                                                                     |
| m-3 | Minor    | TODO.md L74-91 / L155-164 に「cross-implementer 干渉」の orphan commit `a089283` (T-F 用 staged 内容に T-J の編集が混入) が記録されている。reflog (`HEAD@{16}`) には残るが、`origin/main..HEAD` の到達可能 commit からは除外され remote 影響なし。                                                                    | accepted-as-is              | 1           | -                 | Main 確認: `git branch -a --contains a089283` 空、`origin/main..HEAD --first-parent` に `a089283` / `4e41bcc` 不出現。最終リポジトリ状態は task-plan.md の意図 (T-F=8fa4df2 / T-I=da5dfaf / T-J=80f3ca8 独立 commit) と一致。Step 9 retrospective で並列 implementer 起動時の git race 改善策を取り上げる。                                                                                   |
| i-1 | Info     | design.md L99-144 の Effect Service skeleton snippet は `ServiceMap.Service<Type>(...)` を使うが、実装は `effect@4.0.0-beta.60` 制約により全プロジェクト一律で `Context.Service<Type>(...)` に置換 (TODO.md L34 T-B notes 記録済)。                                                                                   | (design deviation, 合理的)  | 1           | -                 | T-B 段階で発見・記録済の deviation。SC-6 観測仕様 (TC-011) は `Layer\.\|ServiceMap\.Service\|ManagedRuntime` を OR で見るため `Context.Service` でも `Layer.<sync\|effect\|succeed>` が hit して PASS する。ただし design.md は更新されていないため、Step 9 で design.md 訂正 or addendum を扱う必要あり。                                                                                    |
| i-2 | Info     | design.md L157-173 の `dynamicLoggerLayer` snippet は外側で `Layer.provideMerge(Env.makeLayer(env))` 1 回で Env 依存を閉じる構造だが、実装 (各 `feature/runtime/server.ts:23-30`) は `dynamicLoggerLayer.pipe(Layer.provide(envLayer))` で内側にも Env を直接 provide する構造に分岐 (TODO.md L34 T-B notes 記録済)。 | (design refinement, 合理的) | 1           | -                 | 実装側の Env 二重 provide は実行時依存解決の安定性確保のための実用調整 (snippet 通りでは Env 解決順序が脆弱)。動作仕様は同一 (Logger 形式が `env.ENV` で切替)。Step 9 で design.md 同期 or 永続 ADR への昇格を判断。                                                                                                                                                                          |
| i-3 | Info     | rss-graphql の既存 86 errors は本サイクル責任外。CI (`vp run --parallel ci`) は ms-01 範囲ではジョブ単位で PASS しており、最終 commit `37576ed` で `gh run list --branch feed-platform-ms-01-workspace-foundation` の `conclusion=success` を確認 (run id 25432854687)。                                              | (consistency check)         | 1           | -                 | SC-10 / TC-024 充足見通し: PASS。3 プロジェクトいずれも CI で Lint / Format / Typecheck / Test / Build を通過しているため Step 8 で Validation 失敗のリスクは低い。                                                                                                                                                                                                                           |
| i-4 | Info     | T-A〜T-L 全 12 タスク `[x]` 完了 + 各 task に commit SHA 記録 + `git log` で全 SHA 到達可能。`progress.yaml` は Step 6 完了を `2026-05-06T11:35:03Z` に記録、Step 7 へ active specialists × 6 を起動済。                                                                                                              | (consistency check)         | 1           | -                 | TODO.md L16〜L199 と git log の 1:1 一致確認。`tasks added later` 節は `None (default)` で再分解の発生なし。                                                                                                                                                                                                                                                                                  |
| i-5 | Info     | ADR-01 (`docs/roadmap/feed-platform/adr/2026-05-05-project-structure-and-runtime.md`) の 5 主要セクション (L13/17/34/112/155) + Decision 内の Q2 / Q2.5 / Q2.6 / Q2.9 / Q2.10 / Q2.11 / Q2.12 全 7 件参照を確認。SC-7 / TC-016 / TC-017 充足見通し: PASS。                                                            | (consistency check)         | 1           | -                 | ADR-02 (`docs/adr/2026-05-05-identity-provider-and-authn-authz-architecture.md`) も 5 主要セクション (L13/17/32/137/171) + Q2.7 / Q2.7-extension / Q2.8 / Q2.11-extension 4 件参照を確認。SC-8 / TC-018 / TC-019 充足見通し: PASS。                                                                                                                                                           |
| i-6 | Info     | SC-1〜SC-11 充足見通し全観測点を holistic 視点で総点検: SC-1 (3 dir + package.json) / SC-3 (smoke test 各 1 件以上 = backend 1 / web 1 / IdP 2) / SC-5 (`find ... -name 'worker.ts' \| wc -l` = 2) / SC-6 (Effect skeleton 5 ファイル × 3) / SC-9 (4 要素 × 2) すべて存在を確認。                                     | (consistency check)         | 1           | -                 | Step 8 (Validation) で `vp run -r check / test / build` 実走と `gh run` 二重チェックを実施すれば全 SC PASS の見通し。SC-2 / SC-4 は M-1 (IdP setup task 欠落) の影響を受ける可能性があるため要注意 (ただし IdP の `vp build` は `setup:cloudflare` 不在でも `wrangler types` 未走で初回 build は型エラー誘発のリスクあり、CI は別実行で PASS なので run id 25432854687 を信頼する)。          |
| i-7 | Info     | 設計確定事項 ↔ 実装の整合: Q2.10 (3 プロジェクト雛形) / Q2.12 (Cloudflare Workers + wrangler 直接 / Vite+Remix) / refinement #1 (Logger Env Service) / refinement #2 (await using) / refinement #3 (PageOrFrame 未採用) いずれも実装側で踏襲を確認。                                                                  | (consistency check)         | 1           | -                 | refinement #1: 各 `feature/runtime/server.ts:11` で `Layer.unwrap(...)` 採用、`import.meta.env.PROD` 直参照は 0 hit (TC-013 充足)。refinement #2: 各 `feature/runtime/hono.ts:17` で `await using runtime = Runtime.make(c.env)` 採用、`runtime.dispose()` 0 hit (TC-014 充足)。refinement #3: `app/app.tsx` 双方で `c.render(<Document>...)` のみ、`createPageOrFrame` 0 hit (TC-022 充足)。 |
| i-8 | Info     | バグ early detection: 3 プロジェクトの `wrangler.jsonc` で `compatibility_date: "2026-02-01"` / `compatibility_flags: ["nodejs_compat"]` が一致、`vars.ENV: "development"` 統一、worker `name` が `feed-platform-backend-<entry>` / `feed-platform-web` / `identity-provider` 規約準拠を確認。                        | (consistency check)         | 1           | -                 | `import.meta.env.PROD` 0 件、Service tag namespace `@app/<project>/feature/<name>/Service` 統一、import path `#@/feature/...` 規約準拠 (`package.json.imports.#@/*` 整合)、TS 7022/7023 自己参照型ループ問題は両 Web プロジェクトで `const app: Hono<AppEnv>` 注釈で解消確認 (`app.tsx:25` / `app.tsx:26`)。                                                                                  |
| i-9 | Info     | Roadmap ms-02 以降への引き継ぎ性: `identity-provider/wrangler.jsonc:22-34` に DB binding 4 種 (`BETTER_AUTH_URL` / `BETTER_AUTH_SECRET` / `d1_databases` / `kv_namespaces`) のコメント予約済。design.md M-1〜M-4 で backend entry 追加手順 5 step を明示 (L843-882)。                                                 | (consistency check)         | 1           | -                 | TC-023 充足見通し: PASS (`grep -E '(d1_databases\|kv_namespaces\|BETTER_AUTH)' wrangler.jsonc` 4 件 hit、JSON キーとしては未有効化)。次マイルストーン implementer が「workspace 整備の手戻り」に遭わない状態。                                                                                                                                                                                |

## Detailed sections

### M-1 detail: identity-provider/vite.config.ts に `setup:cloudflare` task が欠落

**根拠ファイル**: `js/app/identity-provider/vite.config.ts:5-15`

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

対比 `js/app/feed-platform-web/vite.config.ts:8-32` (採用案):

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

**design.md 規定 (該当箇所)**:

- L31: 「`feed-platform-web` / `identity-provider` は `setup:cloudflare` (= `wrangler types`) + `build` の 2 タスク」
- L797 (C-4): 「`feed-platform-web` と完全同形」「将来 ms-02 で `setup:better-auth` / `setup:kysely` を追加する際の拡張点はこの 1 ファイルに集中する」
- L1158 (Mapping to SC-4): 「B-4, C-4 で web/IdP = `vp build` 実体ビルド」
- L1040 (拡張ポイント表): 「`vite.config.ts` の `setup:*` task: `setup:cloudflare` (web / IdP)」

**影響範囲**:

1. `vp run --filter identity-provider setup` で `worker-configuration.d.ts` が**生成されない** (現状ファイル不在を確認済)。
2. `vp run --filter identity-provider build` 時に `dependsOn: ['setup']` がないため、初回 build で `worker-configuration.d.ts` 由来の `Cloudflare.Env` 型が解決できない (= TS5083 / 型推論失敗のリスク)。CI が PASS しているのは `@cloudflare/vite-plugin` が build pipeline 内部で `wrangler types` を呼ぶ可能性、または現状の型参照が `Cloudflare.Env` を経由しないルート (`Type as EnvType from '#@/feature/env.ts'` のみ) になっているため。
3. ms-02 (Better Auth + D1) で D1/KV bindings を追加した際、型生成 task がないと wrangler bindings 由来の型が `worker-configuration.d.ts` に反映されず、`c.env.DB` 等の型が `unknown` 扱いになる。

**推奨対応**:

- 修正: `js/app/identity-provider/vite.config.ts` を `feed-platform-web/vite.config.ts` と完全同形に揃える (= `defineTaskInputFromOutput` import + `setup:cloudflare` task 追加 + `build.dependsOn: ['setup']`)。
- 同時修正: `js/app/identity-provider/.gitignore` に `worker-configuration.d.ts` を 1 行追加 (m-1 finding 一括解消)。
- 想定 implementer task: T-I の re_activation (`re_activations: 1`) または新規 patch task として登録。修正粒度は数分。

**Severity 判定根拠**: Blocker ではない理由 = (a) SC-9 観測仕様字面 (`[ -f vite.config.ts ]`) は満たす、(b) CI / vp run は最終 commit で PASS、(c) ms-01 段階では IdP の `c.env` は `Type as EnvType from '#@/feature/env.ts'` 経由で解決され `worker-configuration.d.ts` 不在の影響が顕在化していない。Major である理由 = design.md「完全同形」明文規定への乖離、ms-02 引き継ぎ時に必ず破綻する潜在問題、3 プロジェクト雛形整備の核心目的 (= 後続 implementer が手戻りなく ms-02 着手できる) を一部毀損。

## Round history metadata

| Round | Date       | Reviewer instance             | Round-only Gate |
| ----- | ---------- | ----------------------------- | --------------- |
| 1     | 2026-05-06 | reviewer (holistic, parallel) | needs_fix       |

Final Gate: `needs_fix`。1 Major (M-1) `pending` / 0 Blocker / 1 `accepted-as-is` (m-3) / 2 Minor (m-1, m-2) `pending`。Step 7 → Step 8 transition は M-1 の解決 (= `fixed` 化 or user 判断による `accepted-as-is` 化) を経由する。Step 6 ↔ Step 7 round-trip 候補: M-1 修正タスク (T-I re_activation または新規 patch task) を Step 6 へ戻して Round 2 へ進む案を Main へ推奨。

<!--
Authoring guide: share-artifacts/references/review-report.md
Detailed state-label semantics and per-aspect emphasis are delegated to specialist-reviewer/SKILL.md.
-->
