# Research Note: past-cycles

- **Identifier:** 2026-05-03-pr-ci-integration
- **Topic:** past-cycles <!-- 過去 dev-workflow サイクル / merged PR / retrospective から PR・CI 運用パターンを抽出 -->
- **Researcher:** researcher (past-cycles 観点)
- **Created at:** 2026-05-03
- **Scope:** 過去 dev-workflow サイクル (`docs/workflow/<date>-*/`) と直近 merged PR を分析し、(1) Draft / Ready 運用、(2) PR 概要更新頻度、(3) CI 失敗の Blocker 化事例、(4) 1 PR あたりのコミット粒度と CI fix 比率、(5) `git-workflow` スキルとの規約重複 を棚卸しする。Intent Spec L117-127 の未解決事項のうち「PR description のフォーマット」への参考素材を提供する。

## 調査対象

本 Research Note が扱うのは「**現行 dev-workflow が暗黙運用してきた PR / CI の事実パターン**」。Intent Spec の以下に対応する:

- 背景 L10-15: 「過去のサイクルでは PR は人間が暗黙運用」「CI 失敗時の対応も場当たり的」の根拠提示
- 未解決事項 L122: 「PR description のフォーマット (テンプレート化要否)」の参考素材
- 制約 L99: 「`specialist-common` の Git ガードレール」「既存スキル `git-workflow` への大規模変更非スコープ」との整合性確認
- 非スコープ L33-40 の枠を超えないこと (`git-workflow` 改修提案は禁止、dev-workflow/SKILL.md 側に閉じて記述する前提)

他の Research Note との境界:

- gh CLI の公式仕様 / オプション挙動 → researcher #1 (external-spec)
- 現行 CI ジョブ構造 / branch protection / 必須チェック → researcher #2 (current-ci)
- dev-workflow/SKILL.md のセクション統合提案 → researcher #3 (skill-integration)

## 発見事項

### F-1: 直近 dev-workflow サイクル PR は #92 と #94 の 2 件のみ

`gh pr list --state merged --limit 30 --json ...` の結果から、dev-workflow サイクルに対応する PR は以下:

| PR # | branch                                 | createdAt            | mergedAt                    | additions / deletions | commit 数 | createdAt 時の `isDraft` |
| ---- | -------------------------------------- | -------------------- | --------------------------- | --------------------- | --------- | ------------------------ |
| #92  | `feat/dev-workflow-retro-followup`     | 2026-04-29T04:18:54Z | 2026-04-29T13:24:38Z (~9h)  | +6979 / -801          | 42        | **`false`**              |
| #94  | `worktree-dazzling-meandering-pudding` | 2026-05-02T02:49:51Z | 2026-05-03T03:56:03Z (~25h) | +6216 / -386          | 45        | **`false`**              |

その他の merged PR は Renovate (`renovate/*`) や非 dev-workflow 系 (`feat/add-nix-workspace` 等) で本観点の対象外。

引用: `/tmp/claude/pr-list.json` (`gh pr list --state merged --limit 30 --json number,title,createdAt,mergedAt,isDraft,additions,deletions,headRefName,baseRefName` 出力)。

### F-2: PR #92 / #94 はいずれも Draft で作成された履歴がない

- `gh pr view 94 --json isDraft,createdAt,mergedAt` → `{"isDraft":false,"createdAt":"2026-05-02T02:49:51Z",...}` (`/tmp/claude/pr-94-meta.json`)
- `gh pr view 92 --json isDraft,createdAt,mergedAt` → `{"isDraft":false,"createdAt":"2026-04-29T04:18:54Z",...}` (`/tmp/claude/pr-92-meta.json`)
- `gh api /repos/totto2727-org/monorepo/issues/{94,92}/timeline` で `event == "ready_for_review"` / `event == "convert_to_draft"` を抽出 → **両 PR ともに 0 件** (`/tmp/claude/pr-94-timeline.json`, `/tmp/claude/pr-92-timeline.json`)

→ 過去サイクルの PR は **常に最初から Ready** で作成されており、Draft → Ready 化のフロー自体が存在しなかった。

### F-3: PR description の編集イベントが timeline に残っていない

- `gh api /repos/.../issues/94/timeline` で `event == "edited"` / `event == "renamed"` の合計件数 = **0** (`jq -r '[.[] | select(.event == "renamed" or .event == "edited")] | length'`)
- PR #92 についても同様に編集イベントなし
- 一方 PR description 本文 (`/tmp/claude/pr-92-body.md` 50 行 / `/tmp/claude/pr-94-body.md` 47 行) は完成度の高いサマリー + Cycle artefacts + Test plan を含む

→ 過去サイクルの PR description は **マージ直前 (またはマージ準備時) に一度だけ書かれた** と推定され、ステップ完了ごとの逐次更新は行われていない。Intent Spec が解決しようとする課題そのもの。

### F-4: 過去 PR 2 件は description 構造が共通している

両 PR とも以下の章立てを共有 (順序は若干異なる):

PR #92 (`/tmp/claude/pr-92-body.md` L1-50):

1. `## Summary` — 目的の 1-3 文 + bullet list (Layout migration / Cycle: ... / Cycle: ... deferred)
2. `## Cycle artefacts` — `docs/dev-workflow/<id>/` 配下成果物の bullet 列挙 (intent-spec / research/ / design / qa-design / qa-flow / task-plan / TODO / review/ / validation-report / retrospective)
3. `## Verification` — 観測コマンド (`test ! -d ...`, `ggrep -rnE ... | wc -l`) のコードブロック
4. `## Notable incidents` — 失敗 / 復旧事例 (chain-substitution bug / baseline mis-selection)
5. `## Test plan` — チェックリスト (`- [x] Step 8 Validation grep checks ...`)
6. 末尾: `🤖 Generated with [Claude Code](https://claude.com/claude-code)` フッター

PR #94 (`/tmp/claude/pr-94-body.md` L1-48):

1. `## Summary` — 主要追加・変更 (bullet) + サブセクション `### 主な追加・変更`
2. `## 設計判断 (確定済)` — design.md からの確定事項
3. `## Cycle Documentation` — `docs/workflow/<id>/` の成果物 + retrospective へのリンク
4. `## Test plan` — チェックリスト (Step 8 Validation 結果, Step 7 External Review 結果)
5. `## Cycle Notes` — ロールバック経緯
6. 末尾: Claude Code 帰属フッター

→ **共通骨子**: `Summary` (bullet list) + `Cycle artefacts/Documentation` (成果物リンク) + `Test plan` (Validation チェックリスト) + `Notable incidents/Cycle Notes` (ロールバック・前提崩壊履歴) + Claude Code フッター。

### F-5: 1 PR あたりコミット数は 42 件 (#92) / 45 件 (#94)、いずれも (`gh pr create` テンプレートの) "Test plan" チェックリストを採用

- PR #92: 42 commits、PR #94: 45 commits (`/tmp/claude/pr-92-commits.txt`, `/tmp/claude/pr-94-commits.txt`)
- 平均 ≈ 43.5 commits / PR
- 両 PR とも `## Test plan` セクションを持ち、bullet 形式のチェックリスト (`- [x] ...`) で Step 8 Validation の確認内容を列挙

### F-6: CI fix を目的とする follow-up commit が PR ごとに発生している

`/tmp/claude/ci-related-commits.txt` (`git log --grep="^ci(" --grep="^fix.*CI" --grep="oxfmt" --grep="formatting"` 出力) を PR コミットリストと突き合わせて抽出:

- PR #92 内の CI fix commit (=`style.*format` / `oxfmt` 系):
  - `0cdbcfc style(dev-workflow): apply oxfmt formatting to cycle artefacts`
  - `9597ecd style(dev-workflow/2026-04-29-retro-cleanup): apply oxfmt formatting ...`
  - 計 **2 / 42 commit ≈ 4.8%**
- PR #94 内の CI fix commit:
  - `165ae8e style(dev-workflow/2026-04-29-add-dev-roadmap-skill): apply oxfmt formatting fixes (35 files, CI fix)` ← **コミットメッセージに「CI fix」を明記**
  - 計 **1 / 45 commit ≈ 2.2%**
- 加えて PR #92 マージ前に独立した commit `93e87d5 fix(dev-workflow/2026-04-26-add-qa-design-step): format retrospective.md and validation-report.md` あり (前サイクル `2026-04-26-add-qa-design-step` 関連)。

→ **過去 PR 平均で 1〜2 commit が CI fix 専用**。Intent Spec の SC-7 (各完了コミット CI PASS) を満たすにはこの fix commit が「リトライ後の最終 success」に該当するパターンが既に定着している。

### F-7: CI status check rollup は両 PR とも全 SUCCESS

`gh pr view {92,94} --json statusCheckRollup` (`/tmp/claude/pr-{92,94}-checks.txt`) で確認:

- PR #94: `check` (workflowName: "CI") + `Analyze (go/javascript-typescript/actions)` (workflowName: "CodeQL") = 計 4 ジョブいずれも `conclusion: "SUCCESS"`、最後の実行は merge 直前
- PR #92: 同構成、全 SUCCESS

→ 過去 PR は最終的にすべての必須チェックを通してマージ済みであり、「CI 赤のままマージ」事例は本サンプル範囲には存在しない。ただし F-6 の通り、途中で format violation が発生し fix commit で復旧した経緯はコミット履歴から読める。

### F-8: 過去サイクルの retrospective には PR / CI への言及がほぼない

`ggrep -rEn "(PR|CI|gh run|gh pr|pull request|Draft|isDraft)" docs/retrospective/` (`/tmp/claude/retro-pr-ci-mentions.txt`) の結果は **2 件のみ**:

- `docs/retrospective/2026-04-29-add-dev-roadmap-skill.md:12` → 「`dev-workflow` (1 サイクル = 1 機能 / 1 PR 規模)」という枕詞 (運用言及ではない)
- `docs/retrospective/2026-04-29-retro-cleanup.md:25` → 「**CI 即時 PASS 期待値**: 直前サイクルで chain bug + フォーマット違反で再修正が発生したのに対し、本サイクルは追記中心で機械置換ゼロのため CI 一発 PASS 見込み」

引用 (retrospective `2026-04-29-retro-cleanup.md` L25):

> **CI 即時 PASS 期待値**: 直前サイクルで chain bug + フォーマット違反で再修正が発生したのに対し、本サイクルは追記中心で機械置換ゼロのため CI 一発 PASS 見込み

→ 過去サイクル振り返りは **CI 失敗が事後的に「気付き」として軽く触れられる程度** で、規約化や Blocker 化の議論は記録されていない。Intent Spec が想定する課題感を裏付ける証拠。

### F-9: 過去サイクル `progress.yaml.blockers` はすべて空配列

`docs/workflow/*/progress.yaml` を grep (`/tmp/claude/blockers-rollbacks.txt`):

| サイクル                                         | `blockers:` |
| ------------------------------------------------ | ----------- |
| `2026-04-24-ai-dlc-plugin-bootstrap`             | `[]`        |
| `2026-04-26-add-qa-design-step`                  | `[]`        |
| `2026-04-29-add-dev-roadmap-skill`               | `[]`        |
| `2026-04-29-integrate-self-review-into-external` | `[]`        |
| `2026-04-29-retro-cleanup`                       | `[]`        |
| `2026-05-03-pr-ci-integration` (本サイクル)      | `[]`        |

→ **CI 失敗が `blockers` に記録された前例はゼロ**。F-6 で観測した CI fix commit (chain-substitution bug、format 違反) はすべて `rollbacks` または retrospective の「課題」セクションに吸収され、`blockers` には登っていない。

ただし `rollbacks` には `Step 4 → Step 1` (前提崩壊リカバリ) や `Step 7 → Step 6` (Major 検出) は記録されており、CI fix 経路だけが `progress.yaml` の構造化記録から漏れている、という不整合がある (`/tmp/claude/blockers-rollbacks.txt` L125-152、`2026-04-29-add-dev-roadmap-skill/progress.yaml` の rollback 履歴参照)。

### F-10: `git-workflow` スキルは PR 作成までは扱うが、Draft / 概要更新 / CI 確認の規約は持たない

`plugins/totto2727/skills/git-workflow/SKILL.md` および配下 references を grep:

- `gh pr create --base <base-branch> --title "<title>" --body "<body>" --assignee @me` の例示が `references/branch-split-workflow.md:68` にあり (PR 作成手順)
- `Phase 4: Present PR URL List` (L72) で「全 PR 作成後に URL を Markdown リストで提示」
- `commit-rules.md:60` に Conventional Commits の type 一覧があり `ci: CI/CD changes` が定義されている
- 一方で **`Draft` / `--draft` / `gh pr ready` / `gh run` / `CI` 結果確認**に関する記述は **存在しない** (`ggrep -E "(Draft|gh run|CI 結果|ready_for_review|isDraft)" plugins/totto2727/skills/git-workflow/` でヒットなし)

→ **`git-workflow` と本サイクル新ルールの規約重複は最小限**。具体的に重複し得るのは:

1. `gh pr create ...` のコマンド形式 (Intent Spec の「Draft PR 作成」は `--draft` フラグ追加が予想される)
2. `Phase 4: Present PR URL List` (PR URL 提示形式)
3. Conventional Commits の `ci(...)` type (本サイクルでも CI fix commit が発生する場合に使用)

これらは「同じ語彙を使うが目的が異なる」関係であり、`git-workflow` を改修せず `dev-workflow/SKILL.md` に閉じて新ルールを書いても矛盾しない (むしろ `git-workflow` の `gh pr create ...` を `--draft` 付きで呼び出す形で参照すれば整合する)。

### F-11: 現行 `dev-workflow/SKILL.md` の PR / CI 記述はほぼ無い

`ggrep -nE "(PR|pull request|gh pr|gh run|CI|Draft|isDraft|continuous integration)" plugins/dev-workflow/skills/dev-workflow/SKILL.md` のヒットは **2 件のみ**:

- L692: 「本ワークフローの task 粒度『1 日以内』、プロジェクト規約が『1 PR = 複数週』」 → 競合事例の例示
- L888: 「デプロイ・観測・SLA 監視 → 本ワークフロー外 (CI/CD パイプライン等)」 → スコープ外定義

→ 既存 `dev-workflow/SKILL.md` には PR / CI 運用ルールが**実質ゼロ**であり、Intent Spec の SC-1〜SC-4 (新ルール 4 種) は完全な追加 (改修ではない) として実装可能。SC-3 grep 期待値 `(CI|continuous integration|gh run) >= 3 件` は新規追加で達成する必要がある。

### F-12: `2026-04-29-add-dev-roadmap-skill` サイクルの post-merge Round 2 ロールバック (M-1〜M-8) は PR マージ後にも作業継続している

`docs/workflow/2026-04-29-add-dev-roadmap-skill/progress.yaml:139-152` (`/tmp/claude/blockers-rollbacks.txt`) で確認できる第 3 ロールバック:

```yaml
- from: 'Step 9: Retrospective (completed)'
  to: 'Step 6: Implementation (Round 2)'
  reason: |
    Post-cycle Minor fix round triggered by user review:
    (M-1) drop metadata.version from all SKILL.md ...
    (M-8) validation-evidence/ ディレクトリ廃止: ...
  at: 2026-05-03T11:00:00Z
```

このロールバックは PR #94 マージ (2026-05-03T03:56:03Z) 後の `2026-05-03T11:00:00Z` に発生しており、PR とサイクルの関係が「PR merged ≠ サイクル完了」になっている例。Intent Spec の SC-8 (「Step 9 完了 = Ready 化」) の運用設計時に、このような post-merge 修正フェーズ (本サイクルでは想定されないが定義は明確にしたい) の取扱を考慮する余地がある (含意 I-7 参照)。

## 引用元

- `gh pr list --state merged --limit 30 --json number,title,createdAt,mergedAt,isDraft,additions,deletions,headRefName,baseRefName` 出力 → `/tmp/claude/pr-list.json`
- `gh pr view 94 --json isDraft,createdAt,readyForReviewAt,url,...` → `/tmp/claude/pr-94-meta.json`, `/tmp/claude/pr-94.json`
- `gh pr view 92 --json ...` → `/tmp/claude/pr-92-meta.json`, `/tmp/claude/pr-92.json`
- `gh api /repos/totto2727-org/monorepo/issues/{94,92}/timeline --paginate` → `/tmp/claude/pr-{94,92}-timeline.json`
- PR description 本文 → `/tmp/claude/pr-94-body.md` (47 行)、`/tmp/claude/pr-92-body.md` (50 行)
- PR commit リスト → `/tmp/claude/pr-94-commits.txt` (45 件)、`/tmp/claude/pr-92-commits.txt` (42 件)
- PR status check rollup → `/tmp/claude/pr-{94,92}-checks.txt`
- `git log --grep="^ci(" --grep="^fix.*CI" --grep="oxfmt" --grep="formatting" --oneline -50` → `/tmp/claude/ci-related-commits.txt`
- `ggrep -rEn "(PR|CI|gh run|gh pr|pull request|Draft|isDraft)" docs/retrospective/` → `/tmp/claude/retro-pr-ci-mentions.txt`
- `progress.yaml` 全件の `blockers:` / `rollbacks:` 抽出 → `/tmp/claude/blockers-rollbacks.txt`
- 個別 retrospective: `docs/retrospective/2026-04-29-retro-cleanup.md:25`、`docs/retrospective/2026-04-29-add-dev-roadmap-skill.md:12,33-39,42-46`
- 個別 progress.yaml: `docs/workflow/2026-04-29-add-dev-roadmap-skill/progress.yaml:125-152` (rollback 3 件記録)
- `plugins/totto2727/skills/git-workflow/SKILL.md` (PR 関連: L6,49,55,56,75)
- `plugins/totto2727/skills/git-workflow/references/branch-split-workflow.md:1,3,15,63,68,70,72,74,77,79,80,94`
- `plugins/totto2727/skills/git-workflow/references/commit-rules.md:60` (Conventional Commits `ci:` type 定義)
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:692,888` (PR / CI への希少な言及)
- `.github/workflows/ci.yaml` (CI workflow 構造、`check` 単一ジョブ + `pull_request` トリガ)
- `docs/workflow/2026-05-03-pr-ci-integration/intent-spec.md:117-127` (未解決事項)

## 設計への含意

### I-1: Draft 運用は完全な新規追加であり、既存運用とのコンフリクトはない (F-1 / F-2)

過去 PR は 100% Ready で作成されているため、新規ルール SC-5 (Draft 作成) は既存運用を壊さず追加できる。Step 3 Design では「`gh pr create --draft` を `initialize cycle` コミットと同じ commit ハッシュ前後で実行する」を推奨し、コミット - PR の対応関係を `progress.yaml` に記録する手順を確定させること。

### I-2: PR description は「マージ直前一括書き」が現行慣行であり、新ルール SC-2 / SC-6 はこれを反転させる (F-3)

各ステップ完了時に description を更新するという要求は、現行慣行 (timeline 上 edit イベント 0) からの行動変容を伴う。Step 3 Design では:

- `$TMPDIR/dev-workflow/<identifier>-pr-body.md` に description テンプレートを置き、ステップ完了ごとに `gh pr edit --body-file ...` で push する手順を採用するか
- それとも Main が SKILL.md に書かれたプロセスに従って毎回再生成するか

を確定させる必要がある。**Intent Spec の Single-Source-of-Progress 原則** (`progress.yaml` が真) と整合させるなら、description 生成ロジックは `progress.yaml` から派生させる方が二重管理を防げる (Intent Spec L97 「PR description は外部公開ビュー (派生表現)」と一致)。

### I-3: PR description テンプレート骨子は過去 2 PR の最大公約数で決まる (F-4)

過去 PR #92 / #94 の共通骨子から導かれる **dev-workflow PR description テンプレート最小要素**:

1. `## Summary` — bullet list (3〜5 項目) で目的 / 主要変更
2. `## Cycle artefacts` (or `Cycle Documentation`) — `docs/workflow/<id>/` 配下成果物への bullet 列挙 (intent-spec, research/, design, qa-design, qa-flow, task-plan, TODO, review/, validation, retrospective)
3. `## Test plan` — Step 8 Validation の SC PASS チェックリスト形式 `- [x] SC-N (説明): 観測値`
4. `## Notable incidents` (or `Cycle Notes`) — ロールバック・前提崩壊履歴 (発生したサイクルでのみ記述)
5. (任意) `## Verification` — 観測コマンドのコードブロック (PR #92 で採用、PR #94 では Test plan に統合)
6. フッター: `🤖 Generated with [Claude Code](...)`

→ Step 3 Design でこの骨子をテンプレ化する場合、サイクル進行に応じてセクションが段階的に埋まる構造 (Step 1 完了で Summary / Cycle artefacts (intent-spec.md のみ)、Step 8 完了で Test plan、Step 9 完了で retrospective リンク追加…) が自然。

### I-4: 1 PR あたりの平均コミット数 ≈ 43、CI fix commit 比率 ≈ 2-5% (F-5 / F-6)

新ルール SC-7 「各完了コミットで CI PASS」を厳守すると、**1 サイクルあたり 1〜2 件の CI fix commit を許容する余地** を Intent Spec の「2 回までリトライ」と整合させる必要がある。具体的には:

- 「リトライ」は `gh run rerun` のような同一 commit 再実行か、それとも fix commit を push する形か → researcher #1 (gh CLI 仕様) で確定すべき論点
- F-6 で観測した過去 fix commit はすべて `style(...)` / `fix(...)` の **新規 commit を push する形** で復旧している (`gh run rerun` の形跡なし) → Step 3 Design の既定値は「**fix commit push** が現行慣行」と判定できる

### I-5: `git-workflow` スキルとの規約重複は意図的に避けられる (F-10)

`git-workflow` は PR 作成 (`gh pr create`) と PR URL 提示までを扱い、Draft / 概要更新 / CI 確認は扱わない。本サイクル新ルールを `dev-workflow/SKILL.md` に閉じて記述しても、`git-workflow` の Conventional Commits / GPG 署名 / `gh pr create` 等の既存規約と矛盾しない。Step 3 Design では:

- 既存 `git-workflow` への参照リンクを `dev-workflow/SKILL.md` 新セクション冒頭で明示する
- `gh pr create --draft` の `--draft` フラグだけ本サイクル新ルールに記述し、それ以外 (`--title` / `--body-file` / `--assignee @me` 等) は `git-workflow` を踏襲する旨を述べる

ことで、規約の単一情報源を維持できる。Intent Spec L100 「既存スキルへの影響最小化」と整合。

### I-6: `progress.yaml.blockers` は CI 失敗を構造化記録する空き枠として活用できる (F-9)

過去 5 サイクル全て `blockers: []` であり、`blockers` セクションは事実上未使用。Intent Spec の「2 回失敗で Blocker 化」はこの空き枠を初めて埋める形となるため、`shared-artifacts/references/progress-yaml.md` に Blocker エントリのスキーマ例を **PR / CI 関連で初出する** 設計判断ができる (Intent Spec L30 「整合性を崩さない最小限の追記は許容」と整合)。

Step 3 Design では Blocker エントリの推奨フィールド (Intent Spec 制約から逆引き):

- `kind: ci_failure`
- `step: <Step N>` / `commit_sha: <SHA>`
- `attempts: <int>` (= 2 で Blocker 化)
- `last_run_url: <gh run view URL>`
- `resolution: pending | resolved` / `resolved_at`

を明示的に推奨することで、Validation 時に `gh run list` ベースの SC-7 検証と紐付けやすくなる。

### I-7: `2026-04-29-add-dev-roadmap-skill` サイクルの post-merge Round 2 ロールバック事例は本サイクルの SC-8 (Ready 化のトリガー条件) の境界条件として明記要 (F-12)

PR #94 はマージ後に Round 2 修正が走っており、もし「Step 9 完了 = Ready 化」を厳格化すると、Round 2 が走るケース (Step 9 → Step 6 への post-merge ロールバック) では Ready 化のタイミングが定義不能になる。Intent Spec L124-126 の未解決事項「Step 9 完了 = Ready 化のトリガー条件」を Step 3 Design で確定させる際、**本サイクル自身は Round 2 が発生しない前提で良い** が、SKILL.md には「Round 2 が発生した場合は再度 Draft に戻すか維持するか」の補足を入れる余地がある。本サイクルは小規模スコープ (intent-spec L17-19) のため最小限の言及で十分。

### I-8: PR description は外部公開ビューであり成果物として永続化しない (Intent Spec 非スコープ L36) との整合性

I-2 / I-3 で示した「`progress.yaml` から派生させる」設計は、Intent Spec L36 (「`docs/workflow/<id>/pr-overview.md` のようなファイルは作らない」) と整合する。**派生ロジック (フォーマッタ) を `dev-workflow/SKILL.md` 内に手順として記述するか、`$TMPDIR` の揮発ファイルに留めるか** を Step 3 Design で確定する。揮発ファイル方針なら Intent Spec L36 と完全整合。

## 残存する不明点

### Q-1: 「リトライ 2 回まで」のリトライ手段は新規 commit push か `gh run rerun` か

F-6 から「**現行慣行は新規 commit push**」と読めるが、Intent Spec L120「`gh run rerun` / `gh run rerun --failed` / 新規コミット push のいずれか / 組み合わせ」のうち、新ルールでどれを採用するかは **researcher #1 (gh CLI 仕様)** の領域。本観点では「過去事例で `gh run rerun` の形跡なし」までで止める。

### Q-2: 必須チェックの定義 (`branch protection` で何が required か)

F-7 で過去 PR の status check rollup は確認済 (`check` + CodeQL 4 ジョブ全 SUCCESS) だが、これらの中で **branch protection が required と指定しているサブセット**は外部観測できていない。過去事例だけでは「全 SUCCESS が要求」か「`check` のみ required」かを区別不能。**researcher #2 (current-ci) の領域** であり本観点では深追いしない。

### Q-3: Round 2 ロールバック時の Ready 化反転ルール

I-7 で言及した post-merge Round 2 (Step 9 → Step 6) 事例は、Intent Spec のドッグフード対象外 (本サイクルは小規模で Round 2 想定なし) だが、**SKILL.md にどこまで記述するか**は Step 3 Design 判断。本サイクルでは「触れない」「軽く触れる (将来拡張余地として 1 行程度)」「Round 2 専用ルールを新設」の 3 案ある。Step 3 で確定すべき。

### Q-4: PR description 更新の頻度

Intent Spec L51 SC-2 検証「`pull request description` 等が 2 件以上ヒット」「内容変化があれば随時更新」と Intent Spec L67 SC-6「複数回更新されている」のしきい値は SKILL.md 文言レベルで「各 Step 完了時に必ず更新」を入れれば自動的に 9 ステップ × 1 = 9 回程度になる、という解釈で良いか。**Step 3 Design で確定**。本観点では過去事例 (timeline edit 0 件) を踏まえ「現行 0 → 新ルール 9」の劇的な行動変容を SKILL.md 文言で担保する必要があると指摘するに留める。
