# Research Note: Operational Rules Mapping (R1〜R15 → Specialist Skills / References)

- **Identifier:** 2026-04-29-retro-cleanup
- **Topic:** operational-rules-mapping
- **Researcher:** researcher Specialist (operational-rules-mapping 観点担当、単一インスタンス)
- **Created at:** 2026-04-29T11:00:00Z
- **Scope:** 過去 3 サイクル retrospective（`2026-04-24-ai-dlc-plugin-bootstrap` / `2026-04-26-add-qa-design-step` / `2026-04-29-integrate-self-review-into-external`）の「次回改善案」由来の運用ルール 15 件 (R1〜R15) について、(1) 推奨追記先、(2) 既存記述との重複有無、(3) 追記文面ドラフト、(4) Step 8 Validation で機械的検証可能なキーワードを確定する。

## 調査対象

本 Research Note は Intent Spec C 軸（本文への運用ルール追記）および D 軸（shared-artifacts/references/\* への運用ルール追記）の **planner / architect / implementer 段階で機械的にタスク分解可能な粒度まで具体化** することを目的とする。スコープ:

- **対象:** `plugins/dev-workflow/skills/specialist-*/SKILL.md` 9 体本文 + `plugins/dev-workflow/skills/shared-artifacts/references/*.md` 12 体
- **非対象:** 構造圧縮 (A 軸 = `dev-workflow/SKILL.md` / `specialist-common/SKILL.md` の references 切り出し)、description 圧縮 (B 軸 = frontmatter 文字数調整)。これらは別 Research Note または直接 Step 3 Design で扱う
- **追記文面の確定:** 本 Research Note では「ドラフト」を提示するのみ。最終文言は Step 3 architect が `design.md` で確定する

## 発見事項

### 全体方針 — 「真のソース」原則

bootstrap retrospective Self-Review Medium #2 / #3、および本 Intent Spec L247 で指摘されているように、同一運用ルールを「Specialist 本文」と「reference」の両方に書くと **真のソース重複アンチパターン** を再現する。本 Note では各 R 項目について「真のソースを 1 箇所に絞り、もう一方は 1 行参照に留める」原則で配置先を決定する。

具体的な配置方針:

- **Specialist 本文 = 「いつ・なぜ実行するか」のトリガー条件と意思決定ガイダンス**（Specialist が活性化された瞬間に必ず読む箇所）
- **shared-artifacts/references/\* = 「具体的な書式・例・チェックリスト」のレシピ**（成果物作成時に参照する箇所）
- **両方に記載する場合は片方を「真のソース」と明記し、もう一方は 1-2 行サマリ + 参照リンクのみ**

### R1 — Design 段階の「委譲チェックリスト」(grep で重複検出)

| 項目 | 内容 |
| --- | --- |
| 由来 | `2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md` L61, L81 |
| 推奨追記先（真のソース） | **`plugins/dev-workflow/skills/shared-artifacts/references/design.md`** |
| 補助参照 | `plugins/dev-workflow/skills/specialist-architect/SKILL.md` 「作業手順」末尾に 1 行参照 |
| 既存記述 | grep 確認: design.md reference / specialist-architect 本文ともに該当なし (`委譲|grep.*重複|真のソース` ヒット 0 件) |
| 追記ドラフト (design.md reference) | **「### 委譲チェックリスト (重複検出)」** 節を新設し、「A スキルから B スキルへ責務を委譲したとき、A 側に同じ情報のコピーが残っていないかを `ggrep -rnF '<集約スキル名>' plugins/dev-workflow/skills/<delegating-skill>/` で確認する。重複が検出された場合、A 側を 1 行参照（`詳細は <B-skill>/SKILL.md または <reference>.md 参照`）に置換する。」を 3-4 行で記述。 |
| 追記ドラフト (specialist-architect 本文) | 「作業手順」の 6-7 番目に「責務委譲が発生した章節について `shared-artifacts/references/design.md` の『委譲チェックリスト』に従い grep で重複検出を行う」を 1 行追加。 |
| Step 8 検証キーワード | `ggrep -nE '委譲チェックリスト\|委譲.*重複\|真のソース' plugins/dev-workflow/skills/shared-artifacts/references/design.md` >= 1 件 |

### R2 — Research の「Claude Code 公式仕様レビュー」必須サブトピック化

| 項目 | 内容 |
| --- | --- |
| 由来 | `2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md` L62, L80 |
| 推奨追記先（真のソース） | **`plugins/dev-workflow/skills/specialist-researcher/SKILL.md`** |
| 既存記述 | grep 確認: 「観点の例」L36-43 に `existing-impl` / `dependencies` 等が列挙されているが Claude Code 公式仕様は無し |
| 追記ドラフト | 「観点の例」リストの末尾に新 1 項目「**`claude-code-spec` — Claude Code 公式仕様レビュー (subagent 階層 / description 長 / hook イベント等のプラットフォーム制約)。メタサイクル (dev-workflow 自己改修) 時は必須サブトピックとして 1 観点を割り当てる**」を追加。 |
| Step 8 検証キーワード | `ggrep -nE 'claude-code-spec\|Claude Code.*公式仕様\|プラットフォーム制約' plugins/dev-workflow/skills/specialist-researcher/SKILL.md` >= 1 件 |
| 補足 | bootstrap で 3 層構成 → 2 層構成のロールバック (約 20 分のロス) を未然に防げた実証あり。再現可能化のためデフォルト観点に昇格させる。 |

### R3 — context window 予算見積もり

| 項目 | 内容 |
| --- | --- |
| 由来 | `2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md` L64, L82 |
| 推奨追記先（真のソース） | **`plugins/dev-workflow/skills/shared-artifacts/references/task-plan.md`** |
| 補助参照 | `plugins/dev-workflow/skills/specialist-planner/SKILL.md` 「作業手順」内で 1 行参照 |
| 既存記述 | grep 確認: 該当なし (`context window\|文脈窓\|累計行数` ヒット 0 件) |
| 追記ドラフト (task-plan.md reference) | 「### Wave 単位の context window 予算 (推奨)」節を新設し、「各 Wave で同時起動する Specialist が読む全スキル・成果物の累計行数を見積もる。Wave 内累計が 3000 行を超える場合は references/ 切り出しか Wave 分割を検討する。」を 3-4 行で記述。 |
| 追記ドラフト (specialist-planner 本文) | 「作業手順」5-6 番目あたりに「Wave 単位で `gwc -l <files>` により context window 予算を見積もる (詳細は task-plan reference 参照)」を 1 行追加。 |
| Step 8 検証キーワード | `ggrep -nE 'context window\|文脈窓\|累計行数' plugins/dev-workflow/skills/shared-artifacts/references/task-plan.md` >= 1 件 |
| 注意 | Intent Spec L150 で「実機能不要の context window 予算見積りは本サイクル非対象」と明記されているが、これは「**Specialist プロンプトに見積り手順を埋め込む** 部分は含み、**実際に予算を超過しないか dogfood で検証する** 部分のみ次サイクル」という解釈が自然。Step 3 architect で確認のうえ、本サイクルでは reference への運用ルール明文化のみに留める案を採る。 |

### R4 — `task-plan` 作成時の `shared-artifacts/references/*` 全件スキャン

| 項目 | 内容 |
| --- | --- |
| 由来 | `2026-04-26-add-qa-design-step/retrospective.md` L54, L65 |
| 推奨追記先（真のソース） | **`plugins/dev-workflow/skills/shared-artifacts/references/task-plan.md`** |
| 補助参照 | `plugins/dev-workflow/skills/specialist-planner/SKILL.md` 「作業手順」に 1 行参照 |
| 既存記述 | grep 確認: planner 本文にも task-plan reference にも該当なし (`shared-artifacts/references/\*` 全件スキャン記述ゼロ) |
| 追記ドラフト (task-plan.md reference) | 「### 影響範囲スキャン (メタサイクル / リネーム伴うサイクルで必須)」節を新設し、「task-plan 作成時、`gls plugins/dev-workflow/skills/shared-artifacts/references/` を実行し、全 reference ファイルが影響を受ける可能性をチェックリストとして列挙する。特に dev-workflow 自己改修 (メタサイクル) の場合は design.md / progress-yaml.md / retrospective.md / todo.md など `Step \d+` 表記を含む reference を全件 grep する。」を 4-5 行で記述。 |
| 追記ドラフト (specialist-planner 本文) | 「作業手順」3-4 番目に「メタサイクルや横断的リネームを伴うサイクルでは `shared-artifacts/references/*` を全件スキャンして影響範囲を確認する (詳細は task-plan reference 参照)」を 1 行追加。 |
| Step 8 検証キーワード | `ggrep -nF 'shared-artifacts/references/' plugins/dev-workflow/skills/specialist-planner/SKILL.md` >= 1 件 (Intent Spec SC-19 と一致) |
| 補足 | 2026-04-26 サイクル T6 で `shared-artifacts/references/*` の一部が範囲外と Step 5 中に発覚した実証あり。 |

### R5 — `progress.yaml` 編集の運用統一

| 項目 | 内容 |
| --- | --- |
| 由来 | `2026-04-26-add-qa-design-step/retrospective.md` L29, L55, L66 |
| 推奨追記先（真のソース） | **`plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md`** |
| 既存記述 | grep 確認: progress-yaml.md / progress.yaml template ともに該当なし (`上書き\|null フィールド\|新フィールド` ヒット 0 件) |
| 追記ドラフト | 「### 新フィールド追加・既存 null フィールド削除の運用」節を新設し、「`artifacts:` セクションに新フィールドを追加する際、既存の null フィールドを **削除 → 追加** の 2 手順ではなく **1 回の Edit で上書き** する。これは pre-commit hook (yaml syntax check) でキー重複エラーを誘発しないための運用統一ルール。」を 3-4 行で記述。 |
| Step 8 検証キーワード | `ggrep -nE '上書き\|null フィールド\|既存 null\|新フィールド' plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md` >= 1 件 (Intent Spec SC-25 と一致) |

### R6 / R11 — gsed `-e` 連鎖の禁止 + 2-phase placeholder ルール (統合)

| 項目 | 内容 |
| --- | --- |
| 由来 | `2026-04-26-add-qa-design-step/retrospective.md` L30, L56, L74 / `2026-04-29-integrate-self-review-into-external/retrospective.md` L34-L40, L78, L87, L102, L112 |
| 推奨追記先（真のソース） | **`plugins/dev-workflow/skills/specialist-implementer/SKILL.md` の「固有の失敗モード」表 + 直後に詳細節** |
| 補助参照 | `plugins/dev-workflow/skills/shared-artifacts/references/implementation-log.md`「発生した問題とその対処」節に 1 行参照 (具体例の格納先) |
| 既存記述 | grep 確認: implementer 本文 / implementation-log.md ともに該当なし (`placeholder\|__SRK_\|2-phase\|chain bug` ヒット 0 件) |
| 追記ドラフト (specialist-implementer 本文) | 「固有の失敗モード」表に新 1 行「`gsed -i -e ... -e ...` の連鎖実行 \| 同一プロセス内で同一行が再評価され chain bug を誘発するため**禁止**。`old → __SRK_NEW<n>__` を別 sed 呼び出し、`__SRK_NEW<n>__ → new` で復元する 2-phase placeholder で実行する。実行前後に `ggrep -F __SRK_ <root>` で 0 件確認」を追加。さらに「## 機械置換タスクの 2-phase placeholder ルール」節を新設し、具体例 (Step 番号シフト等) を 1 例だけ記述。 |
| 追記ドラフト (implementation-log.md reference) | 「発生した問題とその対処」節に 1 行「機械置換 chain bug が発生した場合は specialist-implementer SKILL.md の 2-phase placeholder ルールに従い再実行 commit を分割する」を追加。 |
| Step 8 検証キーワード | `ggrep -nE '2-phase\|placeholder\|__SRK_' plugins/dev-workflow/skills/specialist-implementer/SKILL.md` >= 1 件 (Intent Spec SC-16 と一致) |
| 統合判断 | R6 (add-qa retrospective 由来) と R11 (integrate-self-review retrospective 由来) は同じルール。R11 で具体的な placeholder 規約が確定したため統合し、implementer 本文を真のソースとする。 |

### R7 — 大規模修正タスクのサブタスク分解推奨

| 項目 | 内容 |
| --- | --- |
| 由来 | `2026-04-26-add-qa-design-step/retrospective.md` L32, L57 |
| 推奨追記先（真のソース） | **`plugins/dev-workflow/skills/specialist-planner/SKILL.md` 「タスク粒度のガイド」節** |
| 補助参照 | `plugins/dev-workflow/skills/shared-artifacts/references/task-plan.md` 「タスク粒度のガイド」表に 1 行追加 |
| 既存記述 | grep 確認: planner 本文の「タスク粒度のガイド」(L72-77) は「数時間〜1 日で完遂可能」「巨大タスク禁止」までは書かれているが、**サブタスク分解の具体例**は無し |
| 追記ドラフト (specialist-planner 本文) | 「タスク粒度のガイド」末尾に「✅ 大規模ファイル全面書き換えタスク (例: `dev-workflow/SKILL.md` 全面書き換え) は **章節単位でサブタスク分解** することを推奨 (例: ステップテーブル / 全体図 / 詳細セクション / コミット規約 / 並列ガイド / ロールバック表 を別 subtask 化)」を追加。 |
| 追記ドラフト (task-plan.md reference) | 「タスク粒度のガイド」表に 1 行「✅ 大規模単一ファイル修正は章節単位でサブタスク分解 \| ❌ 1 タスクに数百行の diff を集約してレビュー困難化」を追加。 |
| Step 8 検証キーワード | `ggrep -nE 'サブタスク\|サブ.?タスク\|sub.?task\|分解' plugins/dev-workflow/skills/specialist-planner/SKILL.md` >= 1 件 (Intent Spec SC-20 と一致、ただし「分解」は既存テキストでもヒットする可能性があるため文脈確認が必要) |
| 補足 | 2026-04-26 T3 (`dev-workflow/SKILL.md` 大規模修正) でレビューしにくい diff になった実証あり。 |

### R8 — メタサイクル影響範囲分析 (shared-artifacts/_ / agents/_ / README / ADR への波及確認)

| 項目 | 内容 |
| --- | --- |
| 由来 | `2026-04-26-add-qa-design-step/retrospective.md` L65 |
| 推奨追記先（真のソース） | **`plugins/dev-workflow/skills/specialist-planner/SKILL.md` 「作業手順」内** |
| 補助参照 | R4 と一体化させ task-plan.md reference の「影響範囲スキャン」節に組み込み可能 |
| 既存記述 | grep 確認: 該当なし (`メタサイクル\|波及\|横断的リネーム` ヒット 0 件) |
| 追記ドラフト (specialist-planner 本文) | 「作業手順」3-4 番目あたり (R4 と統合可) に「メタサイクル (dev-workflow 自己改修) では `shared-artifacts/_*` / `agents/_*` / `README.md` / `doc/adr/_*` への波及確認を必須化する。各ディレクトリで `ggrep -rnE '<changed-keyword>'` を実行し影響範囲を task-plan.md の前提節に列挙する」を追加。 |
| Step 8 検証キーワード | `ggrep -nE 'メタサイクル\|波及\|agents/\*\|README' plugins/dev-workflow/skills/specialist-planner/SKILL.md` >= 1 件 |
| 統合判断 | R4 (全 reference スキャン) と R8 (shared-artifacts/agents/README/ADR) は近接しているため、planner 本文では 1 つの「影響範囲スキャン手順」節として統合し、対象範囲を「reference 全件 + agents/ + README + ADR」と列挙する案が読みやすい。Step 3 architect で確定。 |

### R9 — researcher の「言語スキル棚卸し」観点

| 項目 | 内容 |
| --- | --- |
| 由来 | `2026-04-26-add-qa-design-step/retrospective.md` L72 |
| 推奨追記先（真のソース） | **`plugins/dev-workflow/skills/specialist-researcher/SKILL.md` の「観点の例」リスト** |
| 既存記述 | grep 確認: researcher 本文「観点の例」(L36-43) に該当なし (`プロジェクト固有スキル\|言語スキル\|プロジェクト.?固有.*スキル` ヒット 0 件) |
| 追記ドラフト | 「観点の例」リストに新 1 項目「**`project-skills` — 該当言語・該当フレームワークのプロジェクト固有スキル (`effect-layer` / `effect-runtime` / `vite-plus` / `moonbit-bestpractice` 等) の棚卸し。実装段階で適用可能なスキルを Design 前に把握する**」を追加。R2 (claude-code-spec) と並べて新観点 2 項目として追加するのが整合的。 |
| Step 8 検証キーワード | `ggrep -nE 'プロジェクト固有スキル\|言語スキル\|プロジェクト.?固有' plugins/dev-workflow/skills/specialist-researcher/SKILL.md` >= 1 件 (Intent Spec SC-22 と一致) |
| 補足 | 2026-04-26 T2 (project-skills 観点) で実証あり。 |

### R10 — architect の代替案 3-5 案推奨

| 項目 | 内容 |
| --- | --- |
| 由来 | `2026-04-26-add-qa-design-step/retrospective.md` L73 |
| 推奨追記先（真のソース） | **`plugins/dev-workflow/skills/shared-artifacts/references/design.md` の「代替案と採用理由」節 + 「品質基準」表** |
| 補助参照 | `plugins/dev-workflow/skills/specialist-architect/SKILL.md` 「作業手順」2 番目を 1 行更新 |
| 既存記述 | grep 確認: design.md reference L48「**必ず 2–3 個の代替案を比較**」/ L83「代替案の比較が 2–3 個ある」/ specialist-architect L57「アプローチの候補を 2–3 個洗い出し」の **3 箇所** を「3-5」に変更必要 |
| 追記ドラフト (design.md reference) | L48 を「**必ず 3-5 個の代替案を比較**する。1-2 案しか書かれていない設計書は検討が浅い。重要な意思決定 (採用 vs 却下のトレードオフが大きいトピック) では特に 3 案以上を必須とする」に変更。L83 表行も「代替案の比較が **3-5 個** ある」に変更。 |
| 追記ドラフト (specialist-architect 本文) | L57 「アプローチの候補を 2–3 個洗い出し」を「アプローチの候補を **3-5 個** 洗い出し」に変更。 |
| Step 8 検証キーワード | `ggrep -nE '3-5\|3〜5\|3 から 5\|3.{0,3}案.{0,3}5' plugins/dev-workflow/skills/specialist-architect/SKILL.md plugins/dev-workflow/skills/shared-artifacts/references/design.md` >= 1 件 (Intent Spec SC-18 と一致) |
| 重要 | 既存「2-3」表記が 3 箇所あるため、Step 6 implementer は 3 箇所すべて変更する必要あり。**機械置換 (gsed)** で実施する場合は R6/R11 の 2-phase placeholder ルールを適用 (`2-3 個 → __SRK_NEW3-5__ → 3-5 個`)。 |

### R12 — メタサイクル baseline commit の明示特定

| 項目 | 内容 |
| --- | --- |
| 由来 | `2026-04-29-integrate-self-review-into-external/retrospective.md` L42-L46, L79, L88, L99, L115 |
| 推奨追記先（真のソース） | **`plugins/dev-workflow/skills/specialist-architect/SKILL.md` 「作業手順」** + **`plugins/dev-workflow/skills/specialist-researcher/SKILL.md` 「観点の例」** の **両方** に役割分担して記述 |
| 既存記述 | grep 確認: architect / researcher 本文ともに該当なし (`baseline\|all-files-in-target-state\|complete Step` のうち architect / researcher 本文に 0 件) |
| 追記ドラフト (specialist-architect 本文) | 「作業手順」末尾に新 1 項目「**メタサイクル時の baseline 特定**: `git log --oneline <prev-cycle-start>..<prev-cycle-end>` で前サイクル commit を一覧化し、最後の `complete Step N (...)` メタコミット (= 'all-files-in-target-state' commit) を baseline として `design.md` に明示記録する。Step 6 で機械置換やリストア操作が必要になった際、復元先を 1 段で決定できる」を追加。design.md template への記録欄追加は Step 3 Design で別途決定。 |
| 追記ドラフト (specialist-researcher 本文) | 「観点の例」末尾の `claude-code-spec` (R2) の直後に「**`previous-cycle-baseline` — 前サイクル成果物の 'all-files-in-target-state' commit (= 最後の `complete Step N` メタコミット) を `git log --oneline` で特定し、メタサイクル時の baseline として記録する。research note に SHA を記載**」を追加。 |
| Step 8 検証キーワード | `ggrep -nE 'baseline\|all-files-in-target-state' plugins/dev-workflow/skills/specialist-architect/SKILL.md plugins/dev-workflow/skills/specialist-researcher/SKILL.md` >= 2 件 (Intent Spec SC-17 と一致) |
| 役割分担の根拠 | researcher は前例調査として SHA を発見、architect は design.md でその SHA を baseline として確定する、という 2 段階。両方に書くが「真のソース」は **architect 側 (design.md への記録ルール)** に置き、researcher 側は「調査観点として特定する」のみ記述する。 |

### R13 — design.md 章節 ↔ template/reference の機械的紐付け

| 項目 | 内容 |
| --- | --- |
| 由来 | `2026-04-29-integrate-self-review-into-external/retrospective.md` L48-L52, L80, L89, L100 |
| 推奨追記先（真のソース） | **`plugins/dev-workflow/skills/shared-artifacts/references/design.md` 「Task Decomposition への引き継ぎポイント」節** |
| 補助参照 | `plugins/dev-workflow/skills/specialist-planner/SKILL.md` 「作業手順」 + `plugins/dev-workflow/skills/specialist-architect/SKILL.md` 「作業手順」末尾に 1 行参照 |
| 既存記述 | grep 確認: design.md reference L74「Task Decomposition への引き継ぎポイント」節は存在するが、template/reference 影響先列挙のフォーマット規約は未定義。`task-plan.md` reference の L34「設計ドキュメント参照箇所: `design.md` の該当章節」が近接記述だが、逆方向 (design.md 側からの紐付け) は未整備 |
| 追記ドラフト (design.md reference) | 「Task Decomposition への引き継ぎポイント」節を拡張し、「各意思決定（代替案 A/B/C 採用理由）の末尾に `→ 影響: templates/<file>.md, references/<file>.md` 形式で**影響を受ける template / reference を必須付与**する。Step 5 planner はこの注記を機械的にスキャンしてタスクの『成果物』欄に列挙する」を 3-4 行で追加。 |
| 追記ドラフト (specialist-planner 本文) | 「作業手順」内に「task-plan.md 作成時、各タスクの『設計参照』欄に design.md の対応セクション L 範囲を明記し、design.md 内の `→ 影響: ...` 注記を機械的にスキャンしてタスク成果物に列挙する」を 1 行追加。 |
| 追記ドラフト (specialist-architect 本文) | 「作業手順」内に「設計判断ごとに `→ 影響: templates/<file>.md, references/<file>.md` を必須付与する (詳細は design.md reference 参照)」を 1 行追加。 |
| Step 8 検証キーワード | `ggrep -nE '章節\|セクション.{0,5}紐付\|template.*reference\|references.*templates\|→ 影響' plugins/dev-workflow/skills/specialist-planner/SKILL.md` >= 1 件 (Intent Spec SC-21 と一致) + `plugins/dev-workflow/skills/shared-artifacts/references/design.md` で同様 1 件以上 |
| 補足 | 2026-04-29 T4 で design.md L324 の約束を planner / implementer が拾い切れず Round 1 Major 7 件のうち多数の遠因となった実証あり。 |

### R14 — holistic 観点での Step 6 戻し抑制 (実証結果の記録 + Round 1 必須化)

| 項目 | 内容 |
| --- | --- |
| 由来 | `2026-04-29-integrate-self-review-into-external/retrospective.md` L26 (実証結果)、L90 (Round 1 必須項目化提案)、L104 (チェックリスト先頭化) |
| 推奨追記先（真のソース） | **`plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` 「観点別のレビュー指針」節に新 `holistic` 小節を追加** |
| 補助参照 | `plugins/dev-workflow/skills/shared-artifacts/references/review-report.md` の holistic 観点項目に 1 行追加 (実証結果の引用) |
| 既存記述 | grep 確認: reviewer 本文 L48 で `holistic` の責務 (Task Plan 完了判定 / design.md 整合性 / Intent Spec 充足見込み / 明白な bug) は明記済み。L53「`holistic` 観点の特性」も存在。ただし「**観点別のレビュー指針**」節 (L88-L122) には `security` / `performance` / `readability` / `test-quality` / `api-design` の 5 観点のみで `holistic` 小節が**欠落**している |
| 追記ドラフト (specialist-reviewer 本文) | 「観点別のレビュー指針」節末尾に新小節 「### holistic」を追加し、以下の 4 項目を Round 1 必須チェックリスト化:<br>1. **design.md と実装の整合性チェック** (design.md の章節ごとに該当実装ファイル / template / reference の更新が完了しているかを `→ 影響: ...` 注記をベースに機械的に確認)<br>2. **Task Plan 完了判定** (全タスクが TODO.md で `completed` か)<br>3. **Intent Spec 成功基準充足見込み** (Step 8 Validation で PASS する見込みがあるか)<br>4. **明白な bug の早期検出** (他観点が拾わない明白なロジックバグ) |
| Step 8 検証キーワード | `ggrep -nE 'design\.md と実装\|design\.md.*整合\|整合性チェック' plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` >= 1 件 (Intent Spec SC-23 と一致) |
| 補足 | 2026-04-29 サイクルで holistic 観点を Round 1 で動かしたことで Round 2 修正のみで完了 (Step 6 戻し 0 件) という実証あり。本サイクルではこの実証結果をテキスト化して reviewer 本文に永続化する。 |

### R15 — deprecation 文書化 vs grep 検出のトレードオフ

| 項目 | 内容 |
| --- | --- |
| 由来 | `2026-04-29-integrate-self-review-into-external/retrospective.md` L98 (intent-analyst 改善案), L105 (validator 改善案), L113 (再利用可能な知見) |
| 推奨追記先（真のソース） | **`plugins/dev-workflow/skills/shared-artifacts/references/validation-report.md` の「成功基準ごとの判定」節 (具体例) + 「メタサイクル特有の注記」節 (新設)** |
| 補助参照 | `plugins/dev-workflow/skills/specialist-validator/SKILL.md` 「観測の品質基準」 / 「固有の失敗モード」表に 1 行参照 |
| 既存記述 | grep 確認: validator 本文 / validation-report.md ともに該当なし (`deprecated\|言い換え\|文書化.*例外` ヒット 0 件) |
| 追記ドラフト (validation-report.md reference) | 「### メタサイクル特有の注記 (deprecation 言い換えパターン)」節を新設し、「メタサイクルで deprecated フィールドを文書として残しつつ grep ベース成功基準で 0 件を達成したい場合、**フィールド名そのものを除去し『整合性レポート』のような言い換えで両立可能**。この判断は validation-report.md の該当 SC 備考欄に『観測可能 + 文書化された例外』として記録する。前例: 2026-04-29 サイクル `progress-yaml.md` / `review-report.md` で `self_review` キー名を除去」を 4-5 行で記述。 |
| 追記ドラフト (specialist-validator 本文) | 「固有の失敗モード」表に新 1 行「deprecated フィールドの言い換えで grep 検証を通すケース \| 観測可能 + 文書化された例外として validation-report.md の該当 SC 備考欄に記録 (詳細は validation-report reference 参照)」を追加。 |
| Step 8 検証キーワード | `ggrep -nE 'deprecated\|言い換え\|文書化.*例外' plugins/dev-workflow/skills/specialist-validator/SKILL.md plugins/dev-workflow/skills/shared-artifacts/references/validation-report.md` >= 1 件 (Intent Spec SC-24 と一致) |
| 補足 | intent-analyst 側の「Intent Spec 成功基準セクションに許容範囲を明記する」改善案 (R15-related) は本サイクルでは validator/validation-report.md 側のみ取り扱い、intent-analyst 本文への追記は別サイクルとする (Intent Spec L150 の方針に整合)。 |

## 引用元

- Intent Spec: `docs/dev-workflow/2026-04-29-retro-cleanup/intent-spec.md` L82-L131 (C / D 軸の本文追記スコープ)
- Bootstrap retrospective: `docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md` L51-L88 (R1 / R2 / R3 由来)
- Add-qa-design-step retrospective: `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md` L52-L78 (R4 / R5 / R6 / R7 / R8 / R9 / R10 由来)
- Integrate-self-review retrospective: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md` L34-L106 (R11 / R12 / R13 / R14 / R15 由来)
- 既存 Specialist スキル: `plugins/dev-workflow/skills/specialist-{architect,researcher,planner,implementer,reviewer,validator,retrospective-writer}/SKILL.md`
- 既存 Reference: `plugins/dev-workflow/skills/shared-artifacts/references/{design,task-plan,progress-yaml,implementation-log,validation-report}.md`
- 既存記述 grep 結果サマリ:
  - `placeholder|__SRK_|2-phase|chain bug` — 0 件 (R6/R11 新規追記)
  - `baseline|all-files-in-target-state` — 1 件 (`dev-workflow/SKILL.md:728` のコミットメッセージ例のみ、specialist 本文には 0 件 → R12 新規追記)
  - `3-5|3〜5` (代替案関連) — 0 件 (R10 で「2-3」を上書き)
  - `委譲|grep.*重複|真のソース` — 0 件 (R1 新規追記)
  - `Claude Code.*公式仕様|プラットフォーム制約` — 0 件 (R2 新規追記)
  - `context window|文脈窓` — 0 件 (R3 新規追記、ただし Intent Spec L47 では言及あり)
  - `shared-artifacts/references/*` 全件スキャン — 0 件 (R4 新規追記)
  - `上書き|null フィールド` (progress-yaml) — 0 件 (R5 新規追記)
  - `サブタスク` — 0 件 (R7 新規追記、ただし「分解」は既存テキストでヒットあり)
  - `メタサイクル|波及` (planner) — 0 件 (R8 新規追記)
  - `プロジェクト固有スキル|言語スキル` (researcher) — 0 件 (R9 新規追記)
  - `章節.*紐付|→ 影響` — 0 件 (R13 新規追記)
  - `design.md と実装|整合性チェック` (reviewer) — 既存反映あるが Round 1 必須項目化は未明文 (R14 補強)
  - `deprecated|言い換え|文書化.*例外` (validator) — 0 件 (R15 新規追記)

## 設計への含意

### 真のソース 1 箇所原則

15 件中、複数箇所への記載が必要なものは R1 / R3 / R6+R11 / R12 / R13 / R15 の 6 件あるが、いずれも「**真のソース 1 箇所 + 補助参照 1 行**」のパターンを徹底することで bootstrap retrospective Self-Review #2 / #3 の重複アンチパターン再発を防げる。Step 3 Design では「真のソース」と「1 行参照」を design.md の「→ 影響: templates/_, references/_」記法 (R13 と整合) で明示する書式を確定すること。

### Step 6 implementer の作業負荷とサブタスク分解

R10 (代替案 3-5 案) の `2-3 → 3-5` 置換 3 箇所は、機械置換 (gsed) を使うか手動 Edit で 3 箇所個別編集するかの選択肢がある。3 箇所のみで 2-phase placeholder の overhead が大きいため**手動 Edit 3 箇所** が妥当だが、この判断は Step 5 planner で明示する。R7 (サブタスク分解推奨) の観点でも、本サイクルの implementer タスクは「specialist-* SKILL.md 本文追記」「shared-artifacts/references/_.md 追記」「特定パターン (R10) の文言置換」を**別タスク**に分解するのが適切。

### Wave 構造への影響

15 件の依存関係を整理すると以下の Wave 構造が浮かぶ:

- **Wave-A (並列可、観点別 reference 追記)**: R5 (progress-yaml.md) / R10 (design.md) / R13 (design.md) / R15 (validation-report.md) — 各 reference ファイルが互いに独立
- **Wave-B (並列可、specialist 本文追記、Wave-A の design.md 修正に依存しない部分)**: R2 + R9 + R12 (researcher、3 観点追加) / R6+R11 (implementer 失敗モード + 2-phase 節) / R14 (reviewer holistic 小節)
- **Wave-C (並列可、specialist 本文追記、Wave-A の reference 確定後に 1 行参照を追加)**: R1 (architect) / R3 (planner) / R4+R8 (planner) / R7 (planner) / R12 (architect baseline 特定) / R13 (planner / architect 1 行参照) / R15 (validator 1 行参照)

ただし planner (specialist-planner/SKILL.md) は R3 / R4 / R7 / R8 / R13 の 5 件が集中するため、**1 implementer = 1 ファイル** ではなく **1 implementer = 1 ファイル × 5 観点** の集約タスクとなる可能性がある。これを R7 ガイドに従い章節別サブタスクに分解するか、planner 本文への追記順序が依存関係を持たないことを利用して 1 タスクに集約するかは、Step 5 planner で確定。

### Intent Spec 成功基準との整合

Intent Spec L181-L191 (SC-16〜SC-25) で機械的検証コマンドが既に定義済み。本 Note の各 R 項目「Step 8 検証キーワード」と SC-NN の対応:

| R 項目 | SC | 整合性 |
| --- | --- | --- |
| R1 (委譲チェックリスト) | (該当 SC なし、本サイクル成功基準には含まれず Step 3 Design で SC 追加可否を判定) | — |
| R2 (Claude Code 公式仕様) | (該当 SC なし、同上) | — |
| R3 (context window) | (該当 SC なし、Intent Spec L150 で「実機能不要」とされている。本 Note では reference に運用ルール明文化のみ提案) | — |
| R4 (全 reference スキャン) | SC-19 | ✅ |
| R5 (progress.yaml null 削除) | SC-25 | ✅ |
| R6+R11 (gsed 2-phase) | SC-16 | ✅ |
| R7 (サブタスク分解) | SC-20 | ✅ |
| R8 (メタサイクル波及) | (該当 SC なし、SC-19 / SC-21 と隣接) | — |
| R9 (言語スキル棚卸し) | SC-22 | ✅ |
| R10 (代替案 3-5 案) | SC-18 | ✅ |
| R12 (baseline 特定) | SC-17 | ✅ |
| R13 (章節 ↔ template 紐付け) | SC-21 | ✅ |
| R14 (holistic Round 1 必須) | SC-23 | ✅ |
| R15 (deprecation 言い換え) | SC-24 | ✅ |

→ Intent Spec の SC は 10/15 R 項目をカバー。残り 5 件 (R1 / R2 / R3 / R8 / 統合 R6+R11 のうち 1) は SC 追加候補として Step 3 architect で検討する余地がある。**ただし Intent Spec を変更するのは Step 1 への回帰になるため、Step 3 では SC 追加せず「reference / specialist 本文への記載のみ」で完結させ、本サイクル後の Validation で grep 検出可能性を別途確認するのが妥当**。

### 本サイクルでの新規構造リスク

R12 (baseline 特定) で architect 本文に「design.md template への記録欄追加」案が出ているが、Intent Spec L91「design.md テンプレートに baseline commit 記録欄を追加するかどうかは Step 3 Design で決定（任意）」と整合する。本 Note では **architect 本文に手順を書く + design.md template への記録欄追加は Step 3 Design で別途決定** という 2 段階を推奨する。

## 残存する不明点

1. **R3 (context window 予算) の本サイクルスコープ判定**: Intent Spec L150 で「実機能不要の context window 予算見積りは本サイクル非対象」とあるが、これは「実際の予算超過テスト」を指すのか「reference への運用ルール明文化」も含むのか曖昧。Step 3 architect で本サイクル取り扱い可否を最終判断。本 Note では「**reference への明文化のみ含める**」案を採用しているが、Step 3 で除外判定された場合は R3 を全削除する分岐がある。

2. **R7 (サブタスク分解) の SC-20 文字列マッチ**: Intent Spec SC-20 のキーワード `'サブタスク|サブ.?タスク|sub.?task|分解'` のうち「分解」は既存 specialist-planner 本文 (例: L9 「タスクに分解」) にもマッチしてしまう。`ggrep -nE` で 1 件以上ヒットは現時点で既に達成されており、本サイクルで追記しなくても SC-20 PASS してしまう懸念がある。Step 3 architect で「より特異性の高いキーワード (例: `章節単位.*分解` / `サブタスク化`) で SC-20 を再定義する」or「本 R7 追記内容の特異キーワードを明示する」のいずれかを判断すべき。

3. **R10 (代替案 3-5 案) の機械置換戦略**: 既存「2-3」表記が 3 箇所 (`design.md` reference L48 / L83 / `specialist-architect` L57)。手動 Edit 3 箇所か gsed 2-phase placeholder か、Step 5 planner で確定。

4. **R12 (baseline) の真のソース最終決定**: architect 本文と researcher 本文の両方に書く案を提示したが、Intent Spec L94 では具体的な配置は明示されていない。「architect が design.md に SHA を記録する」「researcher が research note に SHA を発見する」の 2 段階を整理する形で両方に書く必要があるかどうかは Step 3 architect で確定。本 Note では「両方に書く + 真のソースは architect 側」と提案する。

5. **R14 (holistic Round 1 必須化) の既存反映度合い**: Intent Spec L249 で「直前サイクルで holistic 観点の責務追加は実施済みのため、未反映分のみ追記」と明示されているが、本 Note の grep 結果では reviewer 本文「観点別のレビュー指針」節に `holistic` 小節が**完全に欠落** していることを確認した (5 観点のみ)。よって本サイクルで新小節追加が必要。Step 3 architect で「holistic 小節を新規追加する」案で確定する見込み。

6. **R6+R11 統合の retrospective-writer 改善案 (再活性化 SHA 列挙)**: Intent Spec L121 で「`再活性化が 1 回以上発生したタスクの SHA 列挙` 欄の retrospective.md template への追加を促す手順を retrospective-writer 本文に追記」と明示されているが、本 Note では R リストに含まれていない。これは Intent Spec C-8 として既に明示されているため、Step 3 architect 段階で別途取り込む必要があるが、**本 Note のスコープ外** (R リスト 15 件) として別 Research Note または Step 3 architect で扱う。

7. **重複統合の最終判断**: 本 Note では R6 と R11、R4 と R8 の統合を提案しているが、それぞれ「真のソース 1 箇所」になるよう統合する場合と、「2 つの異なる文脈で別々に書く」場合のトレードオフがある。Step 3 architect で最終決定。

---

以上、15 件 (R1〜R15) について Specialist 本文 / reference への配置先 + 追記ドラフト + Step 8 検証キーワードを確定した。Step 3 architect はこの Note を入力に design.md の「本文追記計画 (C / D 軸)」セクションを書き、Step 5 planner はそれを 1 タスク = 1 ファイル粒度のタスクに分解できる。
