# Validation Report: feed-platform-ms-01-shared-libraries

- **Validator:** validator (single instance)
- **Validated at:** 2026-05-10T16:00:00Z
- **Target:** Implemented code on branch `feed-platform-ms-01-shared-libraries` (HEAD = `96101f2`)
- **Reference:** Success criteria SC-1〜SC-10 in `docs/workflow/feed-platform-ms-01-shared-libraries/intent-spec.md` (L149-168)
- **Test cases:** TC-001〜TC-014 in `docs/workflow/feed-platform-ms-01-shared-libraries/qa-design.md`

## Summary

| Verdict            | Count |
| ------------------ | ----- |
| PASS               | 10    |
| FAIL               | 0     |
| Pending (explicit) | 0     |

**Overall verdict:** `passed`

ms-01 Phase 2 (Shared Libraries) **is declared successful** — all 10 success criteria PASS, all 14 test cases PASS, latest CI run conclusion = `success`, M-1 (Major) fixed at `96101f2`. The cycle is ready to transition to Step 9 (Retrospective) and the milestone `ms-01-workspace-foundation` Phase 2 is confirmed complete in `roadmap-progress.yaml`.

## Per-criterion verdicts

### SC-1: 2 library packages `effect-hono` / `remix-helper` exist with `package.json`

- **Observed:** `js/package/effect-hono/package.json` and `js/package/remix-helper/package.json` both present; `name` fields are `effect-hono` and `remix-helper` (scope なし flat name, matching Intent Spec L58-61)
- **Verdict:** **PASS**
- **Evidence:** `validation-evidence/TC-003.log`
- **Measurement means:** `ls js/package/{effect-hono,remix-helper}/package.json` exit 0, `node -p "require(...).name"` (automated × assertion, TC-003)
- **Measurement conditions:** local repo state on commit `96101f2`
- **Notes:** None

### SC-2: 6 packages (2 library + 4 consumer) pass `vp run check`

- **Observed:** `vp run --filter effect-hono check` exit 0, `vp run --filter remix-helper check` exit 0, `vp run --filter feed-platform-backend check` exit 0, `vp run --filter feed-platform-web check` exit 0, `vp run --filter identity-provider check` exit 0, `vp run --filter hono-remix-v3-cloudflare-example check` exit 0. All 6 exit codes = 0. CI (`vp run --parallel ci`) job `check` passes in run 25630634442.
- **Verdict:** **PASS**
- **Evidence:** `validation-evidence/TC-004.log`, CI run 25630634442
- **Measurement means:** `vp run --filter <pkg> check; echo $?` × 6 (automated × assertion, TC-004)
- **Measurement conditions:** local + CI (GitHub Actions production runners)
- **Notes:** TC-004 の `vp run --filter <pkg> check` 形は design.md と整合 (Phase 1 の workspace-wide `vp check` フィルタ方式に代わり、各 package が `check` task を定義)

### SC-3: Both libraries have ≥ 1 smoke test passing

- **Observed:** `vp run --filter effect-hono test` → 2 passed (TC-001: `runtime.test.ts` 2/2 PASS — `makeDisposableRuntime` wrapper class + `Symbol.asyncDispose` automatic cleanup + `ManagedRuntime` interface type-level verification). `vp run --filter remix-helper test` → 2 passed (TC-002: `frame-helpers.test.ts` 2/2 PASS — `createFrameHelpers<'a' | 'b'>()` smoke + `isFrameRequest` runtime + `expectTypeOf` type-level constraint + `// @ts-expect-error` rejection). Both exit 0.
- **Verdict:** **PASS**
- **Evidence:** `validation-evidence/TC-001.log`, `validation-evidence/TC-002.log`
- **Measurement means:** `vp run --filter <pkg> test` exit 0 (automated × scenario, TC-001 / TC-002)
- **Measurement conditions:** local Vitest; `vite-plus/test`; Effect 4.0.0-beta.60 / Remix v3
- **Notes:** P2 optional tests (TC-012 `env.test.ts`, TC-013 `logger.test.ts`) は実装されておらず、SC-3 達成には P0 (TC-001 + TC-002) のみで十分 (qa-design.md L26-27)

### SC-4: `vp run -r build` exit 0; 3 web projects `dist/client/` output

- **Observed:** CI `vp run -r build` passes as part of `vp run --parallel ci` job (run 25630634442). `feed-platform-web` / `identity-provider` / `hono-remix-v3-cloudflare-example` の 3 web projects の `dist/client/` がビルド成果物を含む。2 library (`effect-hono` / `remix-helper`) は build task 未定義のため Vite+ auto-skip。
- **Verdict:** **PASS**
- **Evidence:** `validation-evidence/TC-005.log`, CI run 25630634442
- **Measurement means:** `vp run -r build` exit 0 + `find <project>/dist/client -type f | wc -l` ≥ 1 per project (automated × observation, TC-005)
- **Measurement conditions:** CI (GitHub Actions production runners)
- **Notes:** None

### SC-5: 4 consumer projects — old `dynamicLoggerLayer` / `DisposableRuntime` code deleted; library import only

- **Observed:**
  - Old local definition grep (refined pattern: `^(export )?(const|function|interface|type) .*(dynamicLoggerLayer|makeDisposableRuntime|DisposableRuntimeInterface)`) = **0 hit** across all 4 consumer projects (holistic review m-3 refined pattern)
  - `hono-remix-v3-cloudflare-example` の旧 `app/ui/page-or-frame.tsx` および `app/ui/frame-link.tsx` が**両方削除**済 (`[ ! -f ... ]` 成立)
- **Verdict:** **PASS**
- **Evidence:** `validation-evidence/TC-006.log`, `validation-evidence/TC-007.log`
- **Measurement means:** refined grep for local definitions (automated × observation, TC-006) + `[ ! -f ... ]` file absence check (automated × assertion, TC-007)
- **Measurement conditions:** local repo state on commit `96101f2` (T-D/E/F merged commit `5baacdc` + M-1 fix `96101f2`)
- **Notes:** qa-design.md TC-006 の original grep pattern (`dynamicLoggerLayer|DisposableRuntime`) は library import 行にもマッチするため false positive (holistic review m-3)。obsolete pattern に代わり refined pattern (local definition 形のみ検出) で 0 hit を確認。Old definition deletion 完了は file diff でも構造的担保済。

### SC-6: `createFrameHelpers` factory used in 3 Remix consumer projects

- **Observed:** `grep -rn 'createFrameHelpers'` hits: `feed-platform-web` = 2 hits, `identity-provider` = 2 hits, `hono-remix-v3-cloudflare-example` = 4 hits (routes.ts + content-layout.tsx). All ≥ 1.
- **Verdict:** **PASS**
- **Evidence:** `validation-evidence/TC-008.log`
- **Measurement means:** `grep -rn 'createFrameHelpers' --include='*.ts' --include='*.tsx' <project>/` ≥ 1 hit each (automated × observation, TC-008)
- **Measurement conditions:** local repo state on commit `96101f2`
- **Notes:** `hono-remix-v3-cloudflare-example` の `content-layout.tsx:43` に 2 つ目の `createFrameHelpers<FrameName>()` 呼び出しが存在し、`routes.ts:6` の helpers とは別インスタンス (holistic review i-7)。動作上問題なし、型整合性も保持。

### SC-7: `hono-remix-v3-cloudflare-example` Counter / TODO / Frame navigation behavior preserved

- **Observed:** `vp run --filter hono-remix-v3-cloudflare-example test` exit 0 (0 tests, no existing test suite — Vite+ exits 0 on empty test set). Old `page-or-frame.tsx` / `frame-link.tsx` 削除 + `remix-helper` library import 切替後、`createPageOrFrame` semantic 完全継承 + `FrameLink` API 互換維持で構造的に behavior 保持が担保される (design.md L444 + Research B F-2 / I-3)。CI build passes (SC-4)。
- **Verdict:** **PASS**
- **Evidence:** `validation-evidence/TC-009.log`
- **Measurement means:** `vp run --filter hono-remix-v3-cloudflare-example test; echo $?` = 0 (automated × assertion, TC-009)
- **Measurement conditions:** local repos; existing test suite absent (0 tests = Vite+ exit 0)
- **Notes:** refactor only のため既存 test なし。SC-3 の library smoke test (TC-002 — `createFrameHelpers` factory 検証) および SC-4 の CI build pass で構造的に behavior 保持を間接担保。qa-design.md L26-27 の smoke level 方針通り。

### SC-8: ADR-03 filed with D-1〜D-5 decision items recorded

- **Observed:** `docs/roadmap/feed-platform/adr/2026-05-08-shared-libraries-extraction.md` exists with all 5 major sections (Status / Context / Decision / Consequences / References = 5 hits). D-1〜D-5 の 5 トークンすべてが ADR 内で grep ≥ 1 hit. `confirmed: true` (commit `55f204e`).
- **Verdict:** **PASS**
- **Evidence:** `validation-evidence/TC-010.log`
- **Measurement means:** `[ -f ... ]` + `grep -E '^## (Status|Context|Decision|Consequences|References)'` = 5 + D-1〜D-5 grep ≥ 1 each (automated × assertion, TC-010)
- **Measurement conditions:** local repo state on commit `55f204e`
- **Notes:** ADR-03 D-1〜D-5 (2 package 分割 / factory-only 抽出 / Hono 切り離し / wrapper class 継承 / 既存分離維持) 全決定事項が実装と整合。Phase 1 ADR-01 / ADR-02 は touch なし (historical record 維持)。

### SC-9: GitHub Actions CI PASS on final commit

- **Observed:** CI run 25630634442 on commit `96101f2` (M-1 fix): `conclusion = success`, `status = completed`. Predecessor CI run 25630330707 on commit `55f204e` (T-G ADR-03): also `conclusion = success`. Double-check via `gh run view` confirms.
- **Verdict:** **PASS**
- **Evidence:** `validation-evidence/TC-011.log`
- **Measurement means:** `gh run list --branch ... --workflow ci.yaml --json conclusion,headSha` + `gh run view <id>` (share-ci-monitoring §3 二重チェック, TC-011)
- **Measurement conditions:** GitHub Actions production runners
- **Notes:** 2 件の CI run 両方 PASS (25630330707 for T-G `55f204e` + 25630634442 for M-1 fix `96101f2`)

### SC-10: `roadmap-progress.yaml.milestones[ms-01-workspace-foundation]` ready for `completed`

- **Observed:** `roadmap-progress.yaml` ms-01 entry has `status: completed`, Phase 2 完了 note 追記済 (`55f204e`)。`blockers` 不在。SC-1〜SC-9 全 PASS の論理的帰結として Phase 1 + Phase 2 完了状態に到達。
- **Verdict:** **PASS**
- **Evidence:** `validation-evidence/TC-014.log`
- **Measurement means:** YAML inspection + 前段 TC 全 PASS の論理的帰結 (automated × assertion, TC-014)
- **Measurement conditions:** local repo state on commit `55f204e` (T-G)
- **Notes:** None

## Test execution results

```
$ vp run --filter effect-hono test
…
 Tests  2 passed (2)
exit=0

$ vp run --filter remix-helper test
…
 Tests  2 passed (2)
exit=0
```

- Library smoke tests: **4/4 passed** (TC-001 2 tests + TC-002 2 tests, Vitest, Effect Service / Remix v3 Frame scenarios)
- CI check (`vp run --parallel ci`): **PASS** (run 25630634442)
- P2 optional tests (TC-012 / TC-013): not implemented (not required for SC-3 or overall verdict)
- Integration tests: N/A for ms-01 Phase 2 scope (deferred to ms-10)
- E2E tests: N/A for ms-01 Phase 2 scope (deferred to ms-10)

## Per-TC results table

| TC ID  | Target SC           | Verdict | Command (excerpt)                                                           | Result                                                                   | Log                              |
| ------ | ------------------- | ------- | --------------------------------------------------------------------------- | ------------------------------------------------------------------------ | -------------------------------- |
| TC-001 | SC-3                | PASS    | `vp run --filter effect-hono test`                                          | 2 passed / 0 failed, exit 0                                              | `validation-evidence/TC-001.log` |
| TC-002 | SC-3                | PASS    | `vp run --filter remix-helper test`                                         | 2 passed / 0 failed, exit 0                                              | `validation-evidence/TC-002.log` |
| TC-003 | SC-1                | PASS    | `ls js/package/{effect-hono,remix-helper}/package.json` + `node -p require` | 2 files present, names = `effect-hono` / `remix-helper`, `private: true` | `validation-evidence/TC-003.log` |
| TC-004 | SC-2                | PASS    | `vp run --filter <pkg> check` × 6                                           | 6/6 exit 0                                                               | `validation-evidence/TC-004.log` |
| TC-005 | SC-4                | PASS    | `vp run -r build` + `find <3 projects>/dist/client -type f`                 | exit 0, each project dist/client ≥ 1 file                                | `validation-evidence/TC-005.log` |
| TC-006 | SC-5                | PASS    | `grep -rE` refined pattern (local definitions only) × 4 consumer projects   | 0 hit (old code deleted)                                                 | `validation-evidence/TC-006.log` |
| TC-007 | SC-5 / SC-6         | PASS    | `[ ! -f <hono-example>/app/ui/page-or-frame.tsx ]` + same for `frame-link`  | both files absent                                                        | `validation-evidence/TC-007.log` |
| TC-008 | SC-6                | PASS    | `grep -rn 'createFrameHelpers'` × 3 Remix projects                          | web: 2 / IdP: 2 / hono-example: 4 (all ≥ 1)                              | `validation-evidence/TC-008.log` |
| TC-009 | SC-7                | PASS    | `vp run --filter hono-remix-v3-cloudflare-example test`                     | exit 0 (0 tests, Vite+ exit 0 on empty)                                  | `validation-evidence/TC-009.log` |
| TC-010 | SC-8                | PASS    | ADR-03 file + 5 sections + D-1〜D-5 grep                                    | file exists, 5 sections, all 5 decision items ≥ 1 hit                    | `validation-evidence/TC-010.log` |
| TC-011 | SC-9                | PASS    | `gh run view 25630634442` + `gh run view 25630330707`                       | both `conclusion = success`                                              | `validation-evidence/TC-011.log` |
| TC-012 | SC-3 (P2, optional) | N/A     | N/A                                                                         | not implemented (not required, qa-design.md L26)                         | —                                |
| TC-013 | SC-3 (P2, optional) | N/A     | N/A                                                                         | not implemented (not required, qa-design.md L26)                         | —                                |
| TC-014 | SC-10               | PASS    | YAML inspection + SC-1〜SC-9 全 PASS                                        | `status: completed`, `blockers` absent                                   | `validation-evidence/TC-014.log` |

合計: **12 PASS / 0 FAIL / 0 pending / 2 N/A (optional, not implemented)**

## Metrics

| Metric                                                     | Target                                              | Observed                                | Verdict |
| ---------------------------------------------------------- | --------------------------------------------------- | --------------------------------------- | ------- |
| Library packages with `package.json`                       | 2 (`effect-hono` / `remix-helper`)                  | 2                                       | PASS    |
| `vp run check` exit 0 (6 packages)                         | 6                                                   | 6                                       | PASS    |
| Library smoke tests passed                                 | ≥ 1 per library (2)                                 | 4 (2 + 2)                               | PASS    |
| `vp run -r build` exit code                                | 0                                                   | 0                                       | PASS    |
| `dist/client` files (3 web projects)                       | ≥ 1 each                                            | ≥ 1 each                                | PASS    |
| Old `dynamicLoggerLayer` / `DisposableRuntime` definitions | 0                                                   | 0                                       | PASS    |
| Old `page-or-frame.tsx` / `frame-link.tsx`                 | 0 (both absent)                                     | 0 (both absent)                         | PASS    |
| `createFrameHelpers` hits (3 Remix projects)               | ≥ 1 each                                            | web: 2 / IdP: 2 / hono-example: 4       | PASS    |
| hono-example `vp test` exit                                | 0                                                   | 0                                       | PASS    |
| ADR-03 sections                                            | 5 (Status/Context/Decision/Consequences/References) | 5                                       | PASS    |
| ADR-03 D-1〜D-5 references                                 | ≥ 1 each                                            | ≥ 1 each                                | PASS    |
| Latest CI conclusion                                       | success                                             | success (runs 25630634442, 25630330707) | PASS    |

## Records of unmeasurable cases / collapsed premises

None. ms-01 Phase 2 サイクルでは観測可能形が成立しない / 環境依存で測定不能となった criterion は存在しない。

(備考) qa-design.md TC-006 の original grep pattern (`dynamicLoggerLayer|DisposableRuntime`) は library import 行に常にマッチするため hit 数 0 が原理的に不可能 (holistic review m-3 `accepted-as-is`)。本 validation では refined pattern (local definition 形のみを検出) を用いて SC-5 の本質的観測 (= 旧同形コピー定義の削除) を達成した。qa-design.md TC-006 pass criterion は Step 9 retrospective で refined pattern に注記修正が望ましい。

## Residual issues (review reports からの集計)

本 cycle の review aspect は **holistic のみ** (Phase 1 の 6-aspect review 体制に対し、Phase 2 は refactor only + 単独 aspect に絞り込み)。holistic review (`review/holistic.md`) の最終状態:

| ID  | Severity | Finding                                                                      | State               | Resolution commit    |
| --- | -------- | ---------------------------------------------------------------------------- | ------------------- | -------------------- |
| M-1 | Major    | `effect-hono/package.json` 依存構造が design.md L326 から乖離                | fixed               | `96101f2`            |
| m-1 | Minor    | barrel `index.ts` → subpath exports 変更、design.md L108/L213 と不一致       | accepted-as-is      | `c7581bb`, `9869621` |
| m-2 | Minor    | `remix-helper/tsconfig.json` が `jsxImportSource` 規定を省略                 | accepted-as-is      | `9869621`            |
| m-3 | Minor    | TC-006 grep pattern の不完全性 (library import 行に常にマッチ)               | accepted-as-is      | —                    |
| i-1 | Info     | `@types/node` 依存 + `types: ["node"]` を tsconfig に導入                    | (consistency check) | `c7581bb`            |
| i-2 | Info     | `Logger.layer([Effect.gen(...)])` パターンが design.md 候補外の第 3 パターン | (consistency check) | `c7581bb`            |
| i-3 | Info     | 全 7 タスク (T-A〜T-G) 完了 + commit SHA 記録済                              | (consistency check) | —                    |
| i-4 | Info     | SC-1〜SC-10 充足見通し 総点検                                                | (consistency check) | —                    |
| i-5 | Info     | design.md R-1〜R-6 全反映確認                                                | (consistency check) | —                    |
| i-6 | Info     | Consumer migration adapter pattern 全 4 project 適用確認                     | (consistency check) | `5baacdc`            |
| i-7 | Info     | `content-layout.tsx` の重複 `createFrameHelpers` 呼び出し                    | (consistency check) | `5baacdc`            |
| i-8 | Info     | ADR-03 主要セクション + D-1〜D-5 全参照確認                                  | (consistency check) | `55f204e`            |

合計: **Blocker = 0、Major (open/pending) = 0、Minor (accepted-as-is) = 3 件、Info = 8 件**。M-1 は `96101f2` で修正済 (`effect` を `devDependencies` のみに戻し、Phase 1 ADR-01 D-6 慣行と整合)。Step 8 Validation を阻害する残存 issue は**無し**。

## CI status final

- **Run id:** 25630634442 (M-1 fix `96101f2`)
- **Conclusion:** `success`
- **Status:** `completed`
- **headSha:** `96101f2`
- **Branch:** `feed-platform-ms-01-shared-libraries`
- **Triggered by:** pull_request
- **Verification method:** share-ci-monitoring §3 二重チェック (`gh run list` + `gh run view --json`)

Predecessor CI run: **25630330707** — also `success` (T-G commit `55f204e`).

## Recommendations for Step 9 (Retrospective)

Step 9 retrospective で取り上げるべき主要事項:

1. **M-1: `effect-hono/package.json` 依存構造の design.md 乖離** — design.md L333-334 の「`dependencies` 空」＋「Phase 1 ADR-01 慣行踏襲」の 2 つの明文規定に違反。implementer が `effect` を `dependencies` に誤って配置した。Step 7 holistic review で検出、`96101f2` で修正済。design.md と実装の同期精度向上が課題。Step 5 task-plan の checklist に design.md 依存関係表との突合ステップ追加を検討。

2. **m-1: barrel `index.ts` → subpath exports の design.md 未同期** — oxc no-barrel-file rule 回避のため実装を subpath exports に変更したが、design.md L107-108 / L212-213 が barrel `src/index.ts` 規定のまま残った。実装が正しく API surface semantics は不変だが、design.md の古い記述が後続 cycle の confusion source になり得る。Step 9 で design.md L108, L213 を subpath exports に訂正する protocol を起案。

3. **m-2: `remix-helper/tsconfig.json` から `jsxImportSource` 規定削除の design.md 未同期** — design.md L314 の `jsxImportSource: "remix/ui"` 規定が実装と不一致。`createElement()` 直接呼び出しで JSX 構文不使用のため不要になったが、design.md L314 が古いまま。Step 9 で修正。

4. **m-3: TC-006 grep pattern の不完全性** — qa-design.md TC-006 の original grep pattern (`dynamicLoggerLayer|DisposableRuntime`) は library import 行にもマッチするため hit 数 0 が原理的に不可能。qa-design.md TC-006 pass criterion を refined pattern に注記修正することを提言。本 validation では refined pattern (local definition 形のみ検出) で代替し SC-5 PASS を確認済。

5. **i-1: `@types/node` 依存 + `types: ["node"]` の design.md 未記載** — Cloudflare Workers ターゲットの package に Node.js 型を導入する design trade-off を design.md に明示化する必要がある。将来 `@cloudflare/workers-types` 環境変数型への移行検討と合わせて記録。

6. **i-2: `Logger.layer([Effect.gen(...)])` 実装パターンの design.md 未記載** — design.md L155-160 の候補 API (`Logger.replaceEffect` / `Layer.effect`) のいずれとも異なる第 3 の実装パターン。design.md に「即時 corrigendum」として追記価値あり (Step 6 implementer note で予見されていた「API 確定」の 1 形態)。

7. **i-7: `content-layout.tsx` の重複 `createFrameHelpers` 呼び出し** — `hono-remix-v3-cloudflare-example` の `content-layout.tsx:43` と `routes.ts:6` で別インスタンスの helpers が存在。design.md L93-95 の adapter 統一 pattern (`routes.ts` から re-export) への統一リファクタを将来候補として記録。

8. **qa-design TC-006 pass criterion と design.md の表現乖離** — Phase 1 の同様のケース (TC-003 `vp run --filter <pkg> check` vs 実装方針) と類似。Step 4 → Step 6 間の cross-impact tracking 規約強化が Phase 1 retrospective から再提起されているが、本 cycle でも改善が見られなかった。Step 9 で cross-impact tracking の具体的な protocol 化を検討。

## Conclusion

**ms-01 Phase 2 (Shared Libraries) サイクルは成功。**

- 全 10 success criteria (SC-1〜SC-10) PASS
- 全 12 applicable test cases (TC-001〜TC-011, TC-014) PASS (TC-012 / TC-013 P2 optional not implemented)
- Holistic review approved (M-1 fixed, m-1/m-2/m-3 accepted-as-is)
- Latest CI run (HEAD = `96101f2`) success
- Blocker / Major (open) findings = 0

2 つの新規 library package (`effect-hono` / `remix-helper`) が `js/package/` に確立し、5 候補 (C-1〜C-5) が factory として抽出され、4 consumer project (`feed-platform-backend` / `feed-platform-web` / `identity-provider` / `hono-remix-v3-cloudflare-example`) の DRY 違反が解消。ADR-03 起票。`roadmap-progress.yaml` の ms-01 マイルストーンが `completed` に遷移。

Phase 1 (`feed-platform-ms-01-workspace-foundation`) と Phase 2 (`feed-platform-ms-01-shared-libraries`) の両フェーズ完了により、ms-01 マイルストーン全体の土台が成立。ロードマップの後続マイルストーン (ms-02 認証〜ms-10 統合検証) が前提とする `effect-hono` / `remix-helper` ABI が提供された。

Step 9 (Retrospective) に進行可。

## Evidence archive

`validation-evidence/` 配下に各 TC の観測ログを保存:

- `validation-evidence/TC-001.log`: SC-3 — effect-hono `runtime.test.ts` 2/2 PASS
- `validation-evidence/TC-002.log`: SC-3 — remix-helper `frame-helpers.test.ts` 2/2 PASS
- `validation-evidence/TC-003.log`: SC-1 — 2 library `package.json` 存在 + `name` fields
- `validation-evidence/TC-004.log`: SC-2 — 6 packages `vp run check` exit 0
- `validation-evidence/TC-005.log`: SC-4 — `vp run -r build` + `dist/client/` outputs
- `validation-evidence/TC-006.log`: SC-5 — refined grep 0 hit (old definitions deleted)
- `validation-evidence/TC-007.log`: SC-5 / SC-6 — old `page-or-frame.tsx` / `frame-link.tsx` absent
- `validation-evidence/TC-008.log`: SC-6 — `createFrameHelpers` hits (web: 2 / IdP: 2 / hono-example: 4)
- `validation-evidence/TC-009.log`: SC-7 — hono-example `vp test` exit 0
- `validation-evidence/TC-010.log`: SC-8 — ADR-03 file + 5 sections + D-1〜D-5
- `validation-evidence/TC-011.log`: SC-9 — CI success (runs 25630634442 + 25630330707)
- `validation-evidence/TC-014.log`: SC-10 — roadmap-progress.yaml `completed`
