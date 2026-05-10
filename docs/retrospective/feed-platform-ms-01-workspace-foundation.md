# Retrospective: feed-platform-ms-01-workspace-foundation

- **Identifier:** feed-platform-ms-01-workspace-foundation
- **Writer:** Main (totto2727)
- **Created at:** 2026-05-07T03:45:15Z
- **Cycle started at:** 2026-05-04T12:55:38Z
- **Cycle completed at:** 2026-05-07T03:45:15Z
- **Duration:** 約 2 日 15 時間
- **Roadmap:** `feed-platform` / milestone `ms-01-workspace-foundation`

## Cycle overview

`feed-platform` ロードマップの起点マイルストーン (ms-01 Workspace Foundation) として、後続 9 マイルストーンが共通基盤として参照する 3 プロジェクト構成 (`feed-platform-backend` / `feed-platform-web` / `identity-provider`) を `js/app/` 配下に整備し、Cloudflare Workers + Hono + Remix v3 + Effect の技術スタックで Hello World レベルの雛形を成立させた。intent-spec の Q2 〜 Q3 で 11 件の決定を会話駆動で確定し、design.md / qa-design.md / task-plan.md / 実装 / 6 review / validation までを 9 ステップ完走。最終結果は **全 11 SC PASS / 26 TC PASS / Blocker 0**、ms-01 サイクル成功。

特筆すべきは、Step 7 (External Review) → Step 8 (Validation) transition で計 7 件の **user-gate-driven refinements** が連続的に発生 (Logger Env Service 経由 / `await using` 自動破棄 / `PageOrFrame` future direction / `src/worker/<entry>/` 構造 / `typecheck` 削除 / 全依存 `devDependencies` 集約 / no-op build 削除 / `process.env.NODE_ENV` 採用 / `feature/<name>.test.ts` colocation) で、当初の Round 1 review 時点の design からは大幅に進化した。これは「会話駆動 / 漸増方式」(`feedback_conversational_workflow.md`) の方針と整合した自然な流れ。

ADR-01 (Roadmap mode) と ADR-02 (General mode) の 2 本を起票し、後続マイルストーン + 将来の他システム再利用に向けた不変記録を確立。validator が 26 evidence ログを残し、SC observation の再現性も担保した。

## What went well (patterns that worked)

- **会話駆動・漸増方式の Intent Clarification**: Q2 〜 Q3 を 1 つずつ確定し intent-spec.md に追記する形式は、複数の構造判断 (workspace / プロジェクト分割 / BFF 配置 / 認証認可アーキテクチャ / 命名 / 実行環境 / ADR 範囲) を相互理解しながら確定でき、後段の手戻りを最小化した
- **Step 7 ↔ Step 6 round-trip の効率**: Round 1 で 12 Major (重複統合 5) flagged → 1 implementer で全修正 → Round 2 で 4 reviewer 並列再 review → 全 approved まで 1 ループで収束
- **Step 7 → Step 8 user-gate-driven refinements の取り込み**: 7 件の refinements を CI を通しながら逐次取り込み、最終 commit 時点で全 SC を満たす状態を維持
- **3 プロジェクト並列実装 (Phase 2)** の成果分離: web / IdP の implementer 2 並列で同形コピー作業を効率化 (干渉事故はあったが最終リポジトリ状態は task-plan の意図通り)
- **validator の 26 evidence log 残置**: Step 8 の観測再現性を担保し、Step 9 retrospective 候補が事実ベースで列挙された
- **既存資産の最大活用**: `hono-remix-v3-cloudflare-example` (1:1 コピーベース) / `saas-example` (`await using` パターン) / `rss-graphql` (build 未定義パッケージの参照) を引用することで設計判断の根拠が明確
- **deviation の SoT 取り込み protocol**: Phase 1 implementer が `ServiceMap.Service → Context.Service` / `dynamicLoggerLayer` Env closure pattern の deviation を発見した時、Round 2 で design.md を実装に合わせて corrigendum 化したパターンが、文書 ↔ 実装乖離を防いだ

## Issues (what did not work well)

### Loop count analysis

| Loop between steps                    | Count     | Root cause                                                                                                                                                                                                     |
| ------------------------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Step 6 ↔ Step 7 (Round 1 ↔ Round 2)   | 1         | Round 1 で flagged された Major 5 件 (重複統合) を Step 6 re_activation で修正、想定範囲内                                                                                                                     |
| Step 7 → Step 6 (re-activation)       | 1         | 同上、12 Major (重複統合 5) を 1 implementer instance で全修正                                                                                                                                                 |
| Step 7 → Step 8 user-gate refinements | 7 commits | User からの逐次 refinement (Logger / await using / src/worker / typecheck / devDependencies / no-op build / process.env.NODE_ENV / test colocation) を CI を通しながら取り込み、想定外の "後段戻し" 連鎖が発生 |
| Step 8 → Step 6                       | 0         | validator が観測した SC は全 PASS、戻しなし                                                                                                                                                                    |
| Step 7 → Step 3                       | 0         | design.md correction (Round 2) は **Step 3 戻しではなく Step 6 内 deviation 取り込み** として処理、Step 3 を再開しない判断                                                                                     |

### Blocker history

- **(なし、Blocker は 0 件)**

### 認識された主要な摩擦

1. **Cross-implementer interference (Phase 2)**: implementer-B (web) と implementer-C (IdP) の並列実行中に、git index 競合で orphan commit `a089283` が発生 (web の T-F commit に IdP の T-J 編集が紛れ込み)。両 implementer の reflog 操作で復旧、最終リポジトリ状態は task-plan の意図通りだが、並列 implementer 起動時の **同一 worktree 操作リスク**が顕在化。holistic reviewer が `accepted-as-is` 判定
2. **rss-graphql の既存 86 errors**: 本サイクル責任外だが、`vp check` workspace-wide が exit ≠ 0 を返すため、SC-2 の観測仕様で「`vp run --filter <pkg> check` を 3 プロジェクト個別実行」を採る形になった。qa-design TC-003 と design.md の表現が乖離した状態のまま (validator が deviation note 化)
3. **Step 7 → Step 8 user-gate refinements の連鎖**: 7 件の refinements が User gate review 中に逐次発生し、その都度 commit / push / CI 待機が連鎖。Round 2 review 後の "User gate 提示" → "User による new finding" → "Step 6 re-activation" → "再 push / 再 CI" のループが 7 回繰り返された
4. **design.md の deviation 反映遅延**: Phase 1 で発見された `Context.Service` rename と `dynamicLoggerLayer` Env closure pattern が、Round 1 review で flag されるまで design.md に反映されなかった。Implementer が deviation を TODO.md notes に記録したが、design.md SoT への即時反映 protocol がなかった

## Improvements for the next cycle

### Process improvements

- **Phase 2 並列 implementer の同一 worktree 操作リスク軽減**: 並列 implementer instance ごとに **異なる worktree (例: `git worktree add`) を使う** か、もしくは作業領域が **ファイル単位で完全に独立した task に限る** (例: web と IdP は別ディレクトリだが、両方とも TODO.md / 共通 artifact を更新するため index 競合リスクあり)
- **Step 7 → Step 8 user-gate refinement 多段化への対応**: User gate 提示前に「review 後、実装変更が必要そうな点があれば一括で出してください」と問い合わせる formal step を入れる。逐次 refinement は CI コストが累積する
- **deviation の design.md SoT 即時反映**: Implementer が design.md と乖離する判断をした場合、TODO.md notes だけでなく **同 commit で design.md correction commit も並走** することで、次の review 時に SoT が古いままにならない
- **新規共通化マイルストーン挿入のタイミング**: 本サイクルで明らかになった 3 重複 (`dynamicLoggerLayer` / `makeDisposableRuntime` / `feature/env.ts` / `isFrameRequest` / `PageOrFrame`) は ms-02 着手前に専用マイルストーンで extraction を確定させる (User 戦略指示 2026-05-06)

### Skill improvements

- **`specialist-implementer.md` に並列 implementer 起動時の worktree 規約追加**: 「並列 implementer は同一 worktree を共有してはならない」もしくは「同一 worktree を共有する場合は git index 操作の同期 protocol を明示」(現在の specialist-common §6 では parallelism axis のみ規定、具体的な git 操作の独立性は未規定)
- **`step-external-review.md` に Round 1 → Round 2 の "design.md 訂正" 規約追加**: Major findings が design.md vs 実装の乖離を指摘する場合、design.md correction commit を Round 2 起動前に Main が必ず作成するフロー
- **`step-validation.md` に "deviation pre-check" 追加**: Step 8 開始時に validator が「Step 7 → Step 8 transition の user-gate refinement の有無」を progress.yaml から確認し、新規 deviation がないか scan する

### Specialist prompt improvements

- `intent-analyst`: 該当 Specialist は本サイクルでは未使用 (Step 1 は Main 単独)、改善候補なし
- `researcher`: 4 並列で起動した researcher が **同じファイル (research-note.md template の各セクション)** を独立に解釈、フォーマットの一貫性に微差が出た。template 準拠を冒頭で明示する文言を追加すると改善
- `architect`: refinement 受領 → design.md update の double-pass パターンが効果的に機能。継続採用
- `qa-analyst`: TC 数 25 件が適切な粒度。改善候補なし
- `planner`: Step 5 は Main 単独、改善候補なし
- `implementer`: **デフォルトで `share-adr` skill (Roadmap / General mode) のパス規約を強調**することで、ADR 起票時の path 誤指定を予防 (本サイクルでは問題なし、予防的)
- `reviewer`: holistic reviewer の "Task Plan 完了判断 / SC 充足見通し" 観点が特に load-bearing。Round 1 で security / performance を Round 2 から除外する判断 (approved 時の re-review 不要規約) は効率化に寄与、継続
- `validator`: 26 evidence log を `validation-evidence/<TC-ID>.log` に保存する形式は再現性が高く優秀。改善候補なし
- `retrospective-writer`: 該当 Specialist は本サイクルでは未使用 (Step 9 は Main 単独)、改善候補なし

## Reusable insights

- **個人開発における user-gate-driven refinement の価値**: 個人開発スコープで User = product owner = end user の場合、Step 7 → Step 8 transition で User が "あれもこれも" と気付くのは正常。これを抑制するより **CI を通した安全な逐次取り込み** で対応する方が、抑制して後段で大きな手戻りになるより低コスト。ただし回数が増えれば retrospective に process improvement として記録すべき
- **Effect 4.x beta における API 仕様の即時検証**: 本サイクル中に `effect@4.0.0-beta.60` が `ServiceMap.Service` 非対応 (`Context.Service` のみ) であることが implementer-A の段階で発見された。design 段階で `node_modules/.pnpm/effect@.../dist/*.d.ts` を確認する習慣を skill 化する候補
- **`process.env.NODE_ENV` の自動設定機構**: wrangler / vite が deploy/dev で自動設定する標準ソースを使うことで、独自 `vars.ENV` 管理の本番 deploy バグを構造的に予防可能 (`https://developers.cloudflare.com/workers/wrangler/bundling/#node_env`)。後続マイルストーンの環境変数管理パターンの基準
- **test colocation 規約**: `feature/<name>.test.ts` で検証対象 module の隣に test を置く規約は、test 内容と検証対象の対応が直感的になり、後続実装者が test 内容を予測しやすい
- **`Context.Service` Service tag namespace 規約**: `@app/<project-name>/feature/<name>/Service` 命名で 9 サービス (3 プロジェクト × 3 service) すべてが unique 化、衝突リスクなし。後続マイルストーンでの新規 Service 追加でも継承する

## Retrospective on user approval gates

- **Step 1 (Intent Clarification)**: approved (`304a9f7`)。Q2 〜 Q3 を 1 つずつ確定する会話駆動方式が機能、reject なし
- **Step 3 (Design)**: approved (`e61e309`)、ただし 3 件の refinement 適用後 (Logger Env Service 経由 / `await using` / `PageOrFrame` future direction)。Round 1 review 前段で User refinement を吸収する形式で reject なしに転換
- **Step 4 (QA Design)**: approved (`4ebdbdb`)。reject なし、validator の観測再現性が高く Step 8 で全 PASS に到達
- **Step 5 (Task Decomposition)**: Main gate (User 承認不要)、12 task の wave 構成が後段で破綻なく完走
- **Step 7 (External Review)**: approved (`b46a524`)、Round 1 needs_fix → Round 2 全 6 aspect approved。さらに User gate review 中に 7 件の refinement が連鎖発生し最終 commit `aa7d0a6` で安定
- **Step 8 (Validation)**: approved (`7ecf833`)、reject なし、全 11 SC / 26 TC PASS

## Retrospective on in-progress user inquiries

- **Count**: 0 件 (`$TMPDIR/dev-workflow/*.md` 一時報告は、PR description ファイル (`feed-platform-ms-01-workspace-foundation-pr-body.md`) を除き作成されず)
- **Main topics**: なし。User gate review 中の refinement は、すべて User の能動的指示として直接受領され、一時 report 経由の Main 判断材料は不要だった
- **意義**: Intent Spec の精度が高く、cycle 中の "Main → User 問い合わせ" が必要な分岐がほぼ発生しなかった。会話駆動・漸増方式の Q2 〜 Q3 確定プロセスが効果を発揮した証左

## Cost / time

- **Wall-clock time per phase** (実時間ベース、PR push 間隔から推定):
  - Step 1 (Intent Clarification): 約 18 時間 (会話駆動の質疑応答が支配的)
  - Step 2 (Research): 約 10 分 (4 researcher 並列、合計 1364 行の Research Note)
  - Step 3 (Design): 約 10 分 (architect 単独、87 KB)
  - Step 4 (QA Design): 約 7 分 (qa-analyst 単独、25 TC + Mermaid flow)
  - Step 5 (Task Decomposition): 約 10 分 (Main 単独、12 task plan)
  - Step 6 (Implementation): 約 4 時間 30 分 (Phase 1: 21 分、Phase 2 並列: 25 分、Phase 3: 9 分、Round 1 fixes: 7 分、各 user-gate refinement: 5-15 分 × 7 = 約 1 時間)
  - Step 7 (External Review): 約 10 分 (Round 1 6 並列、Round 2 4 並列)
  - Step 8 (Validation): 約 10 分 (validator 単独、26 evidence log)
  - Step 9 (Retrospective): 約 15 分 (Main 単独、本ファイル)
- **Number of Specialist launches**: 14 (researcher × 4 + architect × 1 + qa-analyst × 1 + implementer × 4 (Phase 1 / Phase 2a / Phase 2b / Phase 3) + Round 1 fix implementer × 1 + reviewer × 6 (Round 1) + reviewer × 4 (Round 2 SendMessage 経由再起動、新規 launch にカウント) + validator × 1 + 構造変更 implementer × 1 + ENV 切替 implementer × 1 + test colocation implementer × 1 (SendMessage 経由) = 約 14 launches)
- **Effective parallelism**:
  - Step 2 Research: 4 並列
  - Step 6 Phase 2: 2 並列 (web + IdP)
  - Step 7 Round 1: 6 並列
  - Step 7 Round 2: 4 並列 (security / performance は Round 1 approved で除外)

## ms-01 サイクル成功宣言

全 SC PASS、Blocker 0、3 プロジェクト雛形 + ADR × 2 起票成立、CI PASS。**ms-01 サイクル成功**。

## 委譲事項 (本 retrospective から後続 / dev-roadmap への引き継ぎ)

- **Step 9 完了直後の dev-roadmap action**: 新規共通化マイルストーン (`dynamicLoggerLayer` / `makeDisposableRuntime` / `feature/env.ts` / `isFrameRequest` / `PageOrFrame` / 他 Remix・Effect 横断ユーティリティ) を ms-02 認証着手前にロードマップへ挿入 (User 戦略指示 2026-05-06)
- **Skill 改善 PR 候補** (本リポジトリで実装可能なもの): 上記「Skill improvements」 / 「Specialist prompt improvements」を `plugins/dev-workflow/skills/specialist-*.md` への PR として整理する候補。本サイクルでは scope 外、別途対応
- **`feedback_conversational_workflow.md` memory** の継続: 「会話駆動・漸増方式」の有効性が本サイクルで再確認された。memory 維持

## ライフサイクル方針

本ファイルは **揮発的** (volatile)。次のサイクルが本ファイルを読み込んで improvements を消化した後、削除される予定。**継続的に有効な決定** (例: deviation 発見時の design.md 即時 corrigendum protocol、`process.env.NODE_ENV` 採用規約) は別途 ADR (`share-adr` 経由) に昇格させる候補。
