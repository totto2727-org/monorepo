# Review Report: Holistic (整合性 / Task Plan 完了 / SC 充足見通し)

- **Cycle:** feed-platform-ms-01-workspace-foundation
- **Aspect:** holistic — 整合性 / Task Plan 完了判断 / design.md 整合 / Intent Spec SC 充足見通し / 明らかなバグの早期検出
- **First reviewed:** 2026-05-06
- **Last updated:** 2026-05-06
- **Final Gate:** approved
- **Round count:** 2

## Findings list

| ID  | Severity | Finding                                                                                                                                                                                                                                                                                                               | State               | First Round | Resolution commit | Notes                                                                                                                                                                                                                                                                                                                                                                                         |
| --- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ----------- | ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| M-1 | Major    | `js/app/identity-provider/vite.config.ts` に `setup:cloudflare` (= `wrangler types`) task が **未定義**。design.md L797 / C-4 が「`feed-platform-web` と完全同形」を明示し、design.md L31 / SC-9 整合性表 (L1158) も同 task の存在を前提にしている。                                                                  | fixed               | 1           | dacf3e4           | Round 2 確認: `js/app/identity-provider/vite.config.ts:1-34` に `defineTaskInputFromOutput` import + `setup` / `setup:cloudflare` task + `build.dependsOn: ['setup']` を追加し `feed-platform-web/vite.config.ts:1-33` と完全同形化。TODO.md T-I `re_activations: 1` (`765f4fa`) で経緯記録。CI (run id 25433694616, head `900b120`) `conclusion=success` 確認。                              |
| m-1 | Minor    | `js/app/identity-provider/.gitignore` に `worker-configuration.d.ts` が記載されておらず `feed-platform-web/.gitignore:3` と divergent。`wrangler types` 実行時に未追跡の生成ファイルが worktree に残る可能性。                                                                                                        | fixed               | 1           | dacf3e4           | Round 2 確認: `js/app/identity-provider/.gitignore:1-3` に `worker-configuration.d.ts` 行追加済。`feed-platform-web/.gitignore:3` と整合。M-1 と一括解消。                                                                                                                                                                                                                                    |
| m-2 | Minor    | `js/app/identity-provider/app/routes.ts:13-15` で `frames = { content: 'content' } as const` のまま (例テンプレートの残骸)。`feed-platform-web/app/routes.ts:13` は `frames = {} as const` に整理済で、3 プロジェクト雛形整備の対称性が崩れている。                                                                   | fixed               | 1           | dacf3e4           | Round 2 確認: `js/app/identity-provider/app/routes.ts:13` を `frames = {} as const` に変更し、docstring も `feed-platform-web/app/routes.ts:1-26` と同形化済 (`...feed-platform-web/app/routes.ts と完全同形` を docstring 末尾に追記)。                                                                                                                                                      |
| m-3 | Minor    | TODO.md L74-91 / L155-164 に「cross-implementer 干渉」の orphan commit `a089283` (T-F 用 staged 内容に T-J の編集が混入) が記録されている。reflog (`HEAD@{16}`) には残るが、`origin/main..HEAD` の到達可能 commit からは除外され remote 影響なし。                                                                    | accepted-as-is      | 1           | -                 | Main 確認: `git branch -a --contains a089283` 空、`origin/main..HEAD --first-parent` に `a089283` / `4e41bcc` 不出現。最終リポジトリ状態は task-plan.md の意図 (T-F=8fa4df2 / T-I=da5dfaf / T-J=80f3ca8 独立 commit) と一致。Step 9 retrospective で並列 implementer 起動時の git race 改善策を取り上げる。                                                                                   |
| i-1 | Info     | design.md L99-144 の Effect Service skeleton snippet は `ServiceMap.Service<Type>(...)` を使うが、実装は `effect@4.0.0-beta.60` 制約により全プロジェクト一律で `Context.Service<Type>(...)` に置換 (TODO.md L34 T-B notes 記録済)。                                                                                   | fixed               | 1           | 900b120           | Round 2 確認: design.md L99-146 の env / greeting / health snippet 3 件を `Context.Service` に置換 + import 文を `import { Context, Layer } from 'effect'` に修正済。L146 (snippet 直下) に「Phase 1 deviation, 2026-05-06 記録」note 追記、CC-6 (L934) export 名規約も `Context.Service` に修正、SC-6 観測仕様 (L1163 / L1218) を OR 表記に拡張。design.md ↔ 実装の整合性が完全に閉じた。    |
| i-2 | Info     | design.md L157-173 の `dynamicLoggerLayer` snippet は外側で `Layer.provideMerge(Env.makeLayer(env))` 1 回で Env 依存を閉じる構造だが、実装 (各 `feature/runtime/server.ts:23-30`) は `dynamicLoggerLayer.pipe(Layer.provide(envLayer))` で内側にも Env を直接 provide する構造に分岐 (TODO.md L34 T-B notes 記録済)。 | fixed               | 1           | 900b120           | Round 2 確認: design.md L155-181 の `runtime/server.ts` snippet を `dynamicLoggerLayer.pipe(Layer.provide(envLayer))` の 2 重 provide 形 + `envLayer` 変数化に修正、inline コメントを「Env を 2 箇所に provide する形式」に書き換え、L211-213 に「Phase 1 deviation, 2026-05-06 記録」note 追記済。動作仕様は不変。                                                                           |
| i-3 | Info     | rss-graphql の既存 86 errors は本サイクル責任外。CI (`vp run --parallel ci`) は ms-01 範囲ではジョブ単位で PASS しており、最終 commit `37576ed` で `gh run list --branch feed-platform-ms-01-workspace-foundation` の `conclusion=success` を確認 (run id 25432854687)。                                              | (consistency check) | 1           | -                 | Round 2 更新: ms-01 final commit は `900b120` に進行、CI run id `25433694616` で `conclusion=success` 維持を確認。SC-10 / TC-024 充足見通し: PASS。Step 9 retrospective で「pre-existing rss-graphql 86 errors」を引き継ぎ事項として明示。                                                                                                                                                    |
| i-4 | Info     | T-A〜T-L 全 12 タスク `[x]` 完了 + 各 task に commit SHA 記録 + `git log` で全 SHA 到達可能。`progress.yaml` は Step 6 完了を `2026-05-06T11:35:03Z` に記録、Step 7 へ active specialists × 6 を起動済。                                                                                                              | (consistency check) | 1           | -                 | Round 2 更新: T-H / T-I の `re_activations: 1` (記録 commit `58daf94` / `765f4fa`) + 修正 commit (`cf489b3` / `dacf3e4`) を反映済。Round 2 後の git log は backend 実装 (T-A〜T-E) と ADR (T-K / T-L) は変更なし、T-F〜T-J 系のみ Round 1 修正で前進。`tasks added later` 節は `None (default)` 維持。                                                                                        |
| i-5 | Info     | ADR-01 (`docs/roadmap/feed-platform/adr/2026-05-05-project-structure-and-runtime.md`) の 5 主要セクション (L13/17/34/112/155) + Decision 内の Q2 / Q2.5 / Q2.6 / Q2.9 / Q2.10 / Q2.11 / Q2.12 全 7 件参照を確認。SC-7 / TC-016 / TC-017 充足見通し: PASS。                                                            | (consistency check) | 1           | -                 | ADR-02 (`docs/adr/2026-05-05-identity-provider-and-authn-authz-architecture.md`) も 5 主要セクション (L13/17/32/137/171) + Q2.7 / Q2.7-extension / Q2.8 / Q2.11-extension 4 件参照を確認。SC-8 / TC-018 / TC-019 充足見通し: PASS。                                                                                                                                                           |
| i-6 | Info     | SC-1〜SC-11 充足見通し全観測点を holistic 視点で総点検: SC-1 (3 dir + package.json) / SC-3 (smoke test 各 1 件以上 = backend 1 / web 2 / IdP 2) / SC-5 (`find ... -name 'worker.ts' \| wc -l` = 2) / SC-6 (Effect skeleton 5 ファイル × 3) / SC-9 (4 要素 × 2) すべて存在を確認。                                     | (consistency check) | 1           | -                 | Round 2 更新: M-1 解消後 SC-2 / SC-4 のリスク懸念は消滅 (`feed-platform-web` と `identity-provider` の `vite.config.ts` が完全同形)。`feed-platform-web/app/smoke.test.ts:6-26` に Health テスト追加 (`cf489b3`) で smoke 件数も 3 プロジェクト対称化 (backend 1 / web 2 / IdP 2)。Step 8 (Validation) で全 SC PASS の見通し: 高。CI run id `25433694616` で head `900b120` 成功確認済。      |
| i-7 | Info     | 設計確定事項 ↔ 実装の整合: Q2.10 (3 プロジェクト雛形) / Q2.12 (Cloudflare Workers + wrangler 直接 / Vite+Remix) / refinement #1 (Logger Env Service) / refinement #2 (await using) / refinement #3 (PageOrFrame 未採用) いずれも実装側で踏襲を確認。                                                                  | (consistency check) | 1           | -                 | refinement #1: 各 `feature/runtime/server.ts:11` で `Layer.unwrap(...)` 採用、`import.meta.env.PROD` 直参照は 0 hit (TC-013 充足)。refinement #2: 各 `feature/runtime/hono.ts:17` で `await using runtime = Runtime.make(c.env)` 採用、`runtime.dispose()` 0 hit (TC-014 充足)。refinement #3: `app/app.tsx` 双方で `c.render(<Document>...)` のみ、`createPageOrFrame` 0 hit (TC-022 充足)。 |
| i-8 | Info     | バグ early detection: 3 プロジェクトの `wrangler.jsonc` で `compatibility_date: "2026-02-01"` / `compatibility_flags: ["nodejs_compat"]` が一致、`vars.ENV: "development"` 統一、worker `name` が `feed-platform-backend-<entry>` / `feed-platform-web` / `identity-provider` 規約準拠を確認。                        | (consistency check) | 1           | -                 | `import.meta.env.PROD` 0 件、Service tag namespace `@app/<project>/feature/<name>/Service` 統一、import path `#@/feature/...` 規約準拠 (`package.json.imports.#@/*` 整合)、TS 7022/7023 自己参照型ループ問題は両 Web プロジェクトで `const app: Hono<AppEnv>` 注釈で解消確認 (`app.tsx:25` / `app.tsx:26`)。                                                                                  |
| i-9 | Info     | Roadmap ms-02 以降への引き継ぎ性: `identity-provider/wrangler.jsonc:22-34` に DB binding 4 種 (`BETTER_AUTH_URL` / `BETTER_AUTH_SECRET` / `d1_databases` / `kv_namespaces`) のコメント予約済。design.md M-1〜M-4 で backend entry 追加手順 5 step を明示 (L843-882)。                                                 | (consistency check) | 1           | -                 | TC-023 充足見通し: PASS (`grep -E '(d1_databases\|kv_namespaces\|BETTER_AUTH)' wrangler.jsonc` 4 件 hit、JSON キーとしては未有効化)。次マイルストーン implementer が「workspace 整備の手戻り」に遭わない状態。                                                                                                                                                                                |

## Detailed sections

### M-1 detail: identity-provider/vite.config.ts に `setup:cloudflare` task が欠落 (Round 2 で fixed)

**Round 1 時点の根拠ファイル (修正前)**: `js/app/identity-provider/vite.config.ts:5-15`

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

**Round 2 解消 (commit `dacf3e4`)**:

- `js/app/identity-provider/vite.config.ts:1-34` を `feed-platform-web/vite.config.ts:1-33` と完全同形化。具体的に追加した要素は (a) `defineTaskInputFromOutput` import、(b) `taskInput.setup.cloudflare` 入力定義、(c) `build.dependsOn: ['setup']` + `taskInput.build` input、(d) `setup` 親 task (no-op) + `setup:cloudflare` (= `wrangler types`) 子 task、(e) docstring に `feed-platform-web/vite.config.ts と完全同形` を明記。
- 副次修正 (m-1 一括解消): `js/app/identity-provider/.gitignore:1-3` に `worker-configuration.d.ts` を追加 (web / backend と同形)。
- 副次修正 (m-2 一括解消): `js/app/identity-provider/app/routes.ts:13` を `frames = {} as const` に揃え、docstring も `feed-platform-web/app/routes.ts:1-26` と同形に書き換え。
- TODO.md T-I に `re_activations: 1` + `re_activation_commits: dacf3e4` を記録 (`765f4fa`)。
- CI 確認: `gh run list --branch feed-platform-ms-01-workspace-foundation --limit 1` で head `900b120` `conclusion=success` (run id 25433694616) を確認。

**Round 2 影響範囲再評価**:

1. `vp run --filter identity-provider setup` で `worker-configuration.d.ts` が **生成可能** (web 同形)。
2. `vp run --filter identity-provider build` の `dependsOn: ['setup']` で初回 build 前に型生成が走る。
3. ms-02 (Better Auth + D1) で D1/KV bindings を追加した際、`wrangler types` で `worker-configuration.d.ts` に bindings 由来型が反映される正常経路が確立。

**Severity 判定** (Round 1 時): Major (design.md「完全同形」明文規定への乖離 + ms-02 引き継ぎ時に必ず破綻する潜在問題)。**Round 2 解決状態**: `fixed`。design.md ↔ 実装の整合性は完全に閉じた。

### Phase 1 deviation 整合化 (Round 2 で i-1 / i-2 fixed)

design.md `900b120` correction で以下 5 点を実装と整合化:

1. L99-146 (Component breakdown - Effect Service skeleton snippet 3 件): `ServiceMap.Service<Type>(...)` → `Context.Service<Type>(...)` 置換 + `import { Context, Layer } from 'effect'` 形式に修正。
2. L146 / L211 (snippet 直下): 「Phase 1 deviation, 2026-05-06 記録」note 追記 (TODO.md T-B notes / ADR-01 への参照を含む)。
3. L155-181 (`runtime/server.ts` snippet): `dynamicLoggerLayer.pipe(Layer.provide(envLayer))` の 2 重 provide 形 + `envLayer` 変数化。inline コメントを「Env を 2 箇所に provide する形式」に書き換え。
4. L934 (CC-6 export 名規約): `Context.Service<Type>(...)` に修正、deviation 経緯を inline 注記。
5. L1163 / L1218 (SC-6 観測仕様 / Mapping table): grep パターンを `Layer / Context.Service / ServiceMap.Service / ManagedRuntime` の OR 表記に拡張。

これにより design.md ↔ 実装の 1:1 整合性が完全に閉じた。Step 9 retrospective での「design 訂正」引き継ぎ事項は不要 (Round 2 内で完結)。

### Round 2 で確認した三重リンクの整合性

cross-implementer deviation 群は次の 3 つの artefact に三重リンクで記録され整合:

1. **TODO.md notes**:
   - T-B (L34): Phase 1 deviation 記録 (Context.Service rename + dynamicLoggerLayer Env closure)
   - T-H (L120-128, `re_activations: 1`): Round 1 修正経緯 + cf489b3 references
   - T-I (L138-153, `re_activations: 1`): Round 1 修正経緯 + dacf3e4 references
   - T-F / T-J (L74-91 / L155-164): orphan commit `a089283` cross-impl 干渉記録 (`accepted-as-is` m-3)
2. **design.md**:
   - L146 / L211 / L934 / L1163 / L1218: Phase 1 deviation note + grep パターン拡張
3. **ADR-01** (`docs/roadmap/feed-platform/adr/2026-05-05-project-structure-and-runtime.md`): 既存の Status / Context / Decision / Consequences / References 5 セクション (commit `de6928f`) は本 Round で更新不要 (deviation は design.md レベルで扱う方針を Round 1 holistic で確認済)。

整合性検証結果: 三重リンクは破綻なし。次マイルストーン implementer が design.md を SoT として参照しても実装と乖離しない状態が成立。

## Round history metadata

| Round | Date       | Reviewer instance                       | Round-only Gate |
| ----- | ---------- | --------------------------------------- | --------------- |
| 1     | 2026-05-06 | reviewer (holistic, parallel)           | needs_fix       |
| 2     | 2026-05-06 | reviewer (holistic, re-review post-fix) | approved        |

Final Gate: `approved`。Round 2 後の状態: 0 Blocker / 0 Major `pending` / 0 Minor `pending` / 4 `fixed` (M-1 / m-1 / m-2 / i-1 / i-2 — 厳密には 5 件、M-1 / m-1 / m-2 は `dacf3e4` で、i-1 / i-2 は `900b120` で解消) / 1 `accepted-as-is` (m-3, orphan commit `a089283` reflog 残存)。

**Step 7 → Step 8 transition 推奨度合い: PASS**。Round 2 で M-1 含む全 Major / Minor が `fixed` 化、design.md ↔ 実装の整合性が完全に閉じ、CI (run id 25433694616, head `900b120`) `conclusion=success` を確認。Step 8 (Validation) で TC-001〜TC-025 実走可能な状態に到達済。

**Step 9 (Retrospective) 引き継ぎ候補**:

1. cross-implementer 干渉 (m-3, orphan `a089283`): 並列 implementer 起動時の git race 改善策 (例: `git update-index --refresh` 強制 / staging area 排他制御)。
2. pre-existing rss-graphql 86 errors (i-3): 本サイクル責任外で継続するが、後続ロードマップで解消が必要。
3. Phase 1 deviation 検出 → design.md 訂正の workflow 改善 (i-1 / i-2): 本サイクルでは Round 2 で design.md correction が成立したが、Step 6 implementation 時点で design.md を即時更新する protocol が望ましい。

<!--
Authoring guide: share-artifacts/references/review-report.md
Detailed state-label semantics and per-aspect emphasis are delegated to specialist-reviewer/SKILL.md.
-->
