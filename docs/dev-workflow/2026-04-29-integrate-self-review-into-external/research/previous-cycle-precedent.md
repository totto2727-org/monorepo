# Research Note: previous-cycle-precedent

- **Identifier:** 2026-04-29-integrate-self-review-into-external
- **Topic:** previous-cycle-precedent (直前サイクル `2026-04-26-add-qa-design-step` の前例分析: Step 追加 → 番号シフトの実例)
- **Researcher:** researcher (single-aspect)
- **Created at:** 2026-04-29T13:10:00Z
- **Scope:** 直前サイクル (Step 4 QA Design 追加 = 旧 9 step → 新 10 step) で適用された番号シフト戦略・成果物パターン・落とし穴を抽出し、本サイクル (Step 7 Self-Review を Step 8 External Review に統合 = 10 step → 9 step) でも再利用できるか判定する。

## 調査対象

本サイクル `2026-04-29-integrate-self-review-into-external` は **逆方向のメタ操作** (ステップ削除 + 統合 + 連動した番号シフト) を扱う。直前サイクル `2026-04-26-add-qa-design-step` は **同種のメタ操作** (ステップ追加 + 番号シフト) を成功裏に完遂しており、両者は方向こそ逆だが「番号シフト・成果物の連鎖更新・複合表現の保護・最終 grep 検証」という共通骨格を持つ。

本 Research Note では、直前サイクルが以下をどう処理したかを抽出する:

- 番号シフトの順序 (gsed 実行順 / placeholder 戦略)
- ファイル編集 / 新規作成 / 削除の物理的内訳
- task-plan の分割粒度 (Wave 構成)
- 連鎖二重置換 (gsed) などのトラブルとその回避策
- 進捗管理 (progress.yaml の active_specialists / completed_steps の運用)
- レビュー観点 (本サイクルが参考にすべき点)

そのうえで「本サイクルでも踏襲すべきパターン」と「避けるべきアンチパターン」を識別し、Step 3 Design / Step 5 Task Decomposition の意思決定材料を提供する。

## 発見事項

### 1. 番号シフトの順序: 逆順 + placeholder 二段階戦略

直前サイクルは旧 Step 5〜9 を新 Step 6〜10 にシフトする際、以下の順で gsed 機械置換を実行した。

- **大原則: 末尾から先頭への逆順実行** (Step 9 → 10、Step 8 → 9、…、Step 4 → 5)
  - 理由: 順方向 (Step 4 → 5、Step 5 → 6、…) で実行すると **連鎖二重置換** が発生する (Step 4 を Step 5 に直した直後、次の Step 5 → 6 が新規 Step 5 まで Step 6 にしてしまう)
  - 出典: `docs/dev-workflow/2026-04-26-add-qa-design-step/research/existing-structure.md:L105` 「**逆順 (9→10, 8→9, ..., 4→5)** で実行」
- **複合表現は事前に placeholder 化**:
  - `Step 5 ↔ Step 6` (ループ表現) → 先に placeholder で待避 → 一括置換後に `Step 6 ↔ Step 7` で復元
  - `Step 5/6` (連結) → 同様に `Step 6/7` へ
  - `Step 5〜6` (範囲表現) → 同様に `Step 6〜7` へ
  - 出典: `git show 55b4bb2` のコミットメッセージ "(Step 5 ↔ Step 6 -> Step 6 ↔ Step 7, Step 5/6 -> Step 6/7, Step 5〜6 -> Step 6〜7)"
- **大規模ファイル (`dev-workflow/SKILL.md`) は機械置換 + Edit ハイブリッド**:
  - 単純な `Step N` → `Step N+1` は gsed
  - ループ図のテキスト説明 (例: 「Step 5 を再活性化」) は前後文脈ごと Edit で書き換え
  - 出典: `research/existing-structure.md:L110` 「ループ図の書き換え: "Step 5 ↔ Step 6" → "Step 6 ↔ Step 7" の機械置換だけでは図の文章説明が崩れるため、Edit で文脈ごと書き換えが必要」

### 2. ファイル内訳の総量と分布

T1〜T7 で触れたファイルは **新規 6 + 修正 ~23 = 計 ~29 ファイル**。

#### 新規ファイル (6 件、すべて T1+T2 で集約)

- `plugins/dev-workflow/skills/specialist-qa-analyst/SKILL.md` (126 行)
- `plugins/dev-workflow/agents/qa-analyst.md` (38 行)
- `plugins/dev-workflow/skills/shared-artifacts/references/qa-design.md` (196 行)
- `plugins/dev-workflow/skills/shared-artifacts/references/qa-flow.md` (219 行)
- `plugins/dev-workflow/skills/shared-artifacts/templates/qa-design.md` (81 行)
- `plugins/dev-workflow/skills/shared-artifacts/templates/qa-flow.md` (60 行)

#### 修正ファイル (T3 + T4 + T5+T7 + T6、計 ~23 件)

| グループ                                    | 件数 | 主な編集内容                                                                                                                              | 担当タスク             |
| ------------------------------------------- | ---- | ----------------------------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| メインスキル本体                            | 1    | `dev-workflow/SKILL.md` を 9→10 step に大改造 (246 行差分)                                                                                | T3                     |
| 入出力契約変更 (3 specialist)               | 3    | planner / implementer / validator の入力欄に qa-design.md/qa-flow.md 追加                                                                 | T4                     |
| 番号シフトのみの specialist skills          | 7    | self-reviewer / reviewer / retrospective-writer / architect / common / intent-analyst / researcher                                        | T5 (T5+T7 統合 commit) |
| agents 定義                                 | 6    | planner / implementer / self-reviewer / reviewer / validator / retrospective-writer                                                       | T5                     |
| shared-artifacts templates (Step 番号参照)  | 3    | TODO.md / self-review-report.md / retrospective.md                                                                                        | T7                     |
| shared-artifacts references (Step 番号参照) | 9    | design / retrospective / todo / self-review-report / research-note / intent-spec / implementation-log / review-report / validation-report | T7                     |
| shared-artifacts スキーマ更新               | 5    | shared-artifacts/SKILL.md / progress.yaml + ref / task-plan template + ref                                                                | T6                     |
| README                                      | 1    | 9-step → 10-step 反映                                                                                                                     | T7                     |

#### 削除ファイル: 0 件

直前サイクルは「追加」のみだったため削除はゼロ。**本サイクルは "ステップ削除" を伴うため、specialist-self-reviewer 関連ファイル群 (skill 本体 + agent 定義 + 関連 reference / template の self-review-report.md) の削除という、前例にはない作業が発生する点に注意**。

### 3. T5+T7 で「漏れ」が発覚した specialist skills

直前サイクル T5 の commit message には、計画外の追加処理が記録されている:

> 4 specialist skills (overlooked in earlier rounds): architect, common, intent-analyst, researcher

これらの specialist skill は task-plan T5 では本来「番号シフトのみで影響なし」と扱う予定だった (新 step が後段挿入のため、Step 4 までしか言及しない specialist は不変のはず) が、実際には Step 番号への参照が本文にあったため追加処理が必要になった。

- 出典: `git show 55b4bb2` の commit message
- 出典: `retrospective.md:L31-32` 「shared-artifacts/references/\* の一部が T6 範囲外だったことが Step 5 中に発覚 (design.md, retrospective.md, todo.md など)。task-plan で漏れたため、追加 gsed バッチで対応する必要があった」

### 4. task-plan の分割粒度: 8 タスク × 4 Wave

直前サイクルは **8 タスク T1〜T8** で完結し、Wave 4 構造 (起点 → 派生 → 派生 → 最終検証) を採用した。

```
Wave 1 (起点、並列可): T1 (qa-design/qa-flow ref+template), T3 (dev-workflow/SKILL.md 大規模更新)
Wave 2 (T1 完了後、並列可): T2 (qa-analyst skill+agent), T4 (planner/implementer/validator I/O), T6 (shared-artifacts schema)
Wave 3 (T3 完了後、並列可): T5 (specialist 番号シフト), T7 (templates 番号シフト + README)
Wave 4 (全完了後、最終): T8 (grep verification)
```

#### 規模分布

- **L (大規模)**: T3 のみ (dev-workflow/SKILL.md 単独で 246 行差分)
- **M (中規模)**: T1, T2, T4, T6 (4 タスク)
- **S (小規模)**: T5, T7, T8 (機械置換中心 + 検証)

retrospective での反省 (`retrospective.md:L33`): 「dev-workflow/SKILL.md の大規模修正 (T3) が 1 タスクに集約されていたため、L 数が多くレビューしにくい diff になった」→ **本サイクルでは T3 相当を更にサブタスクに分解する改善案** が next-cycle 改善案として明記されている。

### 5. 連鎖二重置換 (gsed) のトラブル発生記録

retrospective によれば、連鎖二重置換は **複数回発生** している (本番影響なし、git diff レビューで気付く):

- 出典: `retrospective.md:L30` 「**gsed の連鎖二重置換問題** が複数回発生 (Step 5〜6 → Step 6〜6 になる)。事前の placeholder 設定が漏れた箇所で発生」

これは **placeholder 戦略を採用していたにもかかわらず、複合表現の事前 grep が漏れた** ことが原因。retrospective の next-cycle 改善案として:

- 出典: `retrospective.md:L56` 「gsed で機械置換する場合は事前に `Step \d+〜\d+|Step \d+ ↔ Step \d+|Step \d+\/\d+` を grep して全件 placeholder 化するルールを implementer reference に追記」

### 6. progress.yaml の運用パターン

直前サイクルの progress.yaml の運用は以下:

- `current_step`: 文字列 ("Step N: Name" 形式) で更新
- `completed_steps`: 配列で各 step の `completed_at` + `artifacts` リストを記録
- `active_specialists`: 完了サイクルでは `[]` (空)。実行中は specialist インスタンス ID を持つ想定
- `artifacts`: トップレベルでも一覧を保持 (`completed_steps` と二重管理)
- `user_approvals`: gate 名 + approved_at + notes で記録
- `rollbacks`: 0 件 (本サイクルは無ロールバック)

#### キー重複エラーの発生

- 出典: `retrospective.md:L29` 「progress.yaml の artifacts セクションでキー重複エラーが 2 回発生 (task_plan, self_review)。新フィールド追加時に既存 null フィールドを残してしまった。pre-commit hook (yaml syntax check) で検出されたため迷彩はないが、commit を 1 回追加する手間が生じた」

→ next-cycle 改善案: 「progress.yaml 編集時は新フィールド追加と既存 null 削除を 1 回の Edit でセットにする運用を documents 系 specialist のスコープ外チェックリストに追記」(`retrospective.md:L55`)

### 7. 番号シフトの「メタサイクル過渡期」現象

本サイクル中は番号体系が新旧混在する。直前サイクルではこれを Intent Spec で明示し、Validation 段階での誤検知を防いだ。

- 出典: `retrospective.md:L83` 「メタサイクルの番号体系過渡期 という概念は、dev-workflow / プラグイン / フレームワーク自身を修正する任意のサイクルで再現する。Intent Spec で明示することで Validation 段階での誤検知を防げる」
- 具体例: self-review-report.md template の `Target` 行を新 step 番号で書く一方、本サイクル成果物 self-review-report.md は旧 step 番号で書かれた (review/backward-compatibility.md:L21-31 で Minor 指摘されたが修正不要判定)

### 8. レビュー観点 (External Review) の選定パターン

直前サイクルは 3 観点でレビュー実施:

- `consistency.md` — Step 番号 / 命名 / ファイル間相互参照の整合性
- `documentation-quality.md` — 文書品質 (記述の網羅性 / 一貫性 / 用語統一)
- `backward-compatibility.md` — 既存サイクル / 既存 specialist / 既存 ADR との互換性

retrospective の next-cycle 改善案 (`retrospective.md:L76`): 「reviewer: backward-compatibility 観点をデフォルト 5 観点 (security/performance/readability/test-quality/api-design) に加えて 6 番目として推奨」→ **メタサイクルでは backward-compatibility が必須観点**。

### 9. retrospective.md template の placeholder 名と表記の不整合 (見過ごされた問題)

T5+T7 commit (`55b4bb2`) で `templates/retrospective.md` のループ表現を以下のように更新した:

```
- | Step 5 ↔ Step 6   | {{loop_5_6}}      | {{root_cause_5_6}}  |
+ | Step 6 ↔ Step 7   | {{loop_5_6}}      | {{root_cause_5_6}}  |
```

→ **placeholder 名 `{{loop_5_6}}` は変更されず、表記だけ Step 6 ↔ Step 7 に**。同様に `{{gate_4_summary}}` が「Step 5 (Task Decomposition)」のラベルで残った。これは表面的に動作するが、placeholder の意味と表記の対応が崩れる **アンチパターン**。retrospective でも自己レビューでも検出されておらず、**本サイクルでも同種の placeholder 名汚染が発生し得る** ため事前対策が必要。

- 出典: `git show 55b4bb2 -- plugins/dev-workflow/skills/shared-artifacts/templates/retrospective.md`

### 10. ループ回数 0 / Blocker 0 / 全 14 成功基準 PASS

直前サイクルは Step 6↔7 ループ・Step 7/8→3 ロールバック・Step 8→6 差し戻し すべて 0 回で完走。Validation で 14 成功基準すべて PASS。

- 出典: `retrospective.md:L37-44` (ループ表)、`validation-report.md:L9-16`

これは **設計品質と Self-Review が機能した結果** だが、本サイクルは「Self-Review ステップ自体を統合する」ため、同じ 0 ループ完走は保証されない (Self-Review の機能を External Review に内包させる新仕様の妥当性検証が必要)。

## 引用元

### 旧サイクル成果物 (本研究の主要 source)

- `docs/dev-workflow/2026-04-26-add-qa-design-step/intent-spec.md:L26-43` (Scope: 旧 Step 4 以降を 1 step 後ろにシフト、全 10 step)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/intent-spec.md:L78` (技術制約: gsed 逆順実行)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/design.md:L46-71` (新規ファイル 6 件 + 修正ファイル ~15 件のテーブル)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/design.md:L298-334` (Task Decomposition への引き継ぎポイント、推奨作業順序 1-8)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/task-plan.md:L18-127` (T1〜T8 タスク定義)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/task-plan.md:L131-145` (依存グラフ Mermaid)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/task-plan.md:L147-156` (Wave 1〜4 構成)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/task-plan.md:L159-164` (R1〜R5 リスクカタログ、特に R2 連鎖二重置換)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/research/existing-structure.md:L103-110` (設計への含意 1-6: 番号シフト順序 / placeholder / shared-artifacts / 任意列 / ロールバック / ループ図書き換え)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md:L29-33` (課題セクション: progress.yaml キー重複 / 連鎖二重置換 / shared-artifacts/refs 漏れ / T3 大規模)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md:L52-77` (next-cycle 改善案、特に L56 placeholder 事前 grep / L57 大規模タスクのサブ分解)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md:L80-84` (再利用可能な知見、特に L83 メタサイクル過渡期)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/validation-report.md:L8-16` (14/14 PASS サマリ)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/review/backward-compatibility.md:L37-59` (互換性観点の評価項目テンプレート)

### git history

- `git show 9587d56` — T3 commit (dev-workflow/SKILL.md 大規模更新、+156/-104 行)
- `git show 55b4bb2` — T5+T7 統合 commit (機械置換、23 ファイル ±88 行) + commit message に placeholder 戦略の詳細記録
- `git show da99b6f` — T1 commit (qa-design/qa-flow の ref+template)
- `git show b1a7b46` — T2 commit (specialist-qa-analyst skill+agent)
- `git show a0e22c2` — T4 commit (planner/implementer/validator I/O 契約)
- `git show e9d4f64` — T6 commit (shared-artifacts schema)
- `git show a778066` — T8 commit (final grep verification PASS)

### 重要 diff 抜粋 (T3)

- `git show 9587d56 -- plugins/dev-workflow/skills/dev-workflow/SKILL.md` の以下セクション差分:
  - L43-67 (ASCII workflow 図、9 → 10 ノード)
  - L73-95 (ステップ一覧テーブル、9 行 → 10 行)
  - L99-146 (Step 4 QA Design 詳細セクション新規挿入)
  - L263-296 (Step 6 ↔ Step 7 ループ図、placeholder 経由でリネーム)
  - L398-424 (コミット規約テーブル、Step 4 行追加 + 全行リネーム)
  - L439-455 (並列起動ガイド、10 行に拡張)
  - L463-493 (ロールバック早見表、Step 4 関連 2 件 + Step 9 → Step 4 1 件追加)

## 設計への含意

### A. 踏襲すべきパターン (本サイクル設計に取り込むべき)

#### A-1. 番号シフトの逆順 + placeholder 二段階戦略 (本サイクルでは「順方向」になる)

本サイクルは **削除方向** (旧 Step 8 → 新 Step 7、旧 Step 9 → 新 Step 8、旧 Step 10 → 新 Step 9) なので、**順方向 (8 → 7、9 → 8、10 → 9) で実行**しないと連鎖二重置換が起きる (例: 末尾から逆順 10 → 9 を先にやると、その後 9 → 8 で新規の Step 9 まで Step 8 に書き換わる)。**直前サイクルとは方向が逆になる点を明示する必要あり**。

- 大原則: シフトの「目的地が小さい場合は順方向」「目的地が大きい場合は逆順」
- 複合表現 (`Step 6 ↔ Step 7`、`Step 7/8`、`Step 6〜7`) は事前に grep で全件抽出 → placeholder 化 → 一括置換 → 復元
- 事前 grep の正規表現テンプレート (retrospective.md:L56 由来): `Step \d+〜\d+|Step \d+ ↔ Step \d+|Step \d+\/\d+`

#### A-2. task-plan の Wave 構造

直前サイクルの 4 Wave 構造をそのまま転用可:

- Wave 1 起点: 新規/削除作業 (本サイクルでは specialist-self-reviewer の削除 + reviewer の責務拡張 ref/template 改修)
- Wave 2 派生: 入出力契約の変更を伴う specialist 修正
- Wave 3 派生: 機械置換中心の番号シフト
- Wave 4 最終: grep verification

ただし本サイクルは **削除を含む** ため Wave 1 に「削除タスク」が新規に登場し、その削除が Wave 2/3 の依存先になる点が違う。

#### A-3. retrospective.md L52-77 の next-cycle 改善案を Step 5 task-plan で実装

直前サイクルの retrospective が「次回改善案」として明示した以下を、本サイクル task-plan で具体化する:

- **大規模修正タスクのサブ分解** (`retrospective.md:L57`) — `dev-workflow/SKILL.md` を本サイクルでも触るが、サブタスク化する (例: 「ステップテーブル更新」「ロールバック早見表更新」「Step 6/7 ループ図削除」を別タスクに)
- **placeholder 事前 grep ルール** (`retrospective.md:L56`) — task-plan に「機械置換タスク前に複合表現を grep 全件列挙する subtask」を追加
- **progress.yaml は新フィールド追加と旧 null 削除を 1 Edit にまとめる** (`retrospective.md:L55`) — 本サイクルで `self_review` フィールドを削除する際、関連する null と一緒に Edit
- **shared-artifacts/references/\* 全件スキャン** (`retrospective.md:L54`) — task-plan 段階で grep して影響範囲を網羅 (前回 T5 で漏れが発覚した教訓)
- **backward-compatibility 観点を External Review にデフォルト追加** (`retrospective.md:L76`) — 本サイクル Step 7 (新番号 → 7 = 旧 8 External Review) で必須観点に

#### A-4. Intent Spec での「番号体系過渡期」の明示

本サイクル中は **新 9-step (Self-Review 廃止) と旧 10-step (Self-Review 残存) が共存** する。直前サイクルと同様に Intent Spec の「制約 → 組織的制約」セクションに過渡期を明示することで、Self-Review / External Review / Validation の各成果物が新旧の番号を混在させていても誤検知が起きないようにする。

#### A-5. 14 件レベルの観測可能な成功基準

直前サイクル Intent Spec は 14 件の成功基準を **ファイル存在 + grep 件数 + 含まれる記述** で定義し、Validation を機械的に PASS/FAIL 判定可能にした。本サイクルでも同様の粒度を採用すべき。具体的には:

- `grep -nF "Step 7 (Self-Review)" plugins/dev-workflow/` が 0 件 (旧表記の根絶)
- `ls plugins/dev-workflow/skills/specialist-self-reviewer/SKILL.md` が File not found (削除確認)
- `ls plugins/dev-workflow/agents/self-reviewer.md` が File not found
- `grep -E "self-review|self_review" plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml` が 0 件
- README が 9-step 表記
- ロールバック早見表で「Step 7 → ...」エントリ 0 件
- など

### B. 避けるべきアンチパターン (前例で見過ごされたもの)

#### B-1. placeholder 名と表記の不整合 (前例の見過ごし)

直前サイクルでは `{{loop_5_6}}` placeholder の表記だけ `Step 6 ↔ Step 7` に書き換えて placeholder 名は据え置きにした。同様に `{{gate_4_summary}}` が `Step 5 (Task Decomposition)` のラベルで使われた。本サイクルでは:

- **placeholder 名は意味的に新番号 / 新概念と一致させる** (例: `{{loop_5_6}}` → `{{loop_impl_review}}` のような意味基準命名に変更、または `{{loop_6_7}}` のような番号基準に統一)
- **本サイクルは Self-Review を廃止するため、関連 placeholder (`{{gate_6_summary}}` など) は完全削除**

#### B-2. T3 のような 1 タスク = 246 行 diff の巨大 commit

直前サイクルの retrospective が反省点として明記した通り、`dev-workflow/SKILL.md` への大規模修正を 1 タスクにまとめると レビュー困難な diff になる。本サイクルでは:

- `dev-workflow/SKILL.md` の修正タスクを **サブタスク化** (ステップ一覧 / ASCII 図 / Step 6/7 ループ図削除 / コミット規約 / 並列ガイド / ロールバック早見表 をそれぞれ別 commit)
- 各 sub-commit を `feat(dev-workflow/<id>/T3-<sub>): ...` のように粒度を粗くしすぎない命名で管理

#### B-3. shared-artifacts/references/\* の漏れ

直前サイクル T5 で 4 件 specialist skill + 9 件 shared-artifacts/references/\* の漏れが発覚し、追加 gsed バッチを発行した。本サイクル task-plan では Wave 1 完了直後に **全 ref / template / agent / skill を grep で網羅スキャンする subtask** を組み込む。

#### B-4. progress.yaml のキー重複

新フィールド追加と旧 null 残存を別 Edit にすると pre-commit hook がキー重複エラーで止まる (前回 2 回発生)。本サイクルは **`self_review` フィールド削除** を伴うため、削除と他フィールド調整を 1 Edit にまとめる運用が必要。

### C. task-plan 分割の参考粒度 (Wave 構成のテンプレート)

直前サイクルの T1〜T8 を本サイクル向けに翻訳すると、参考粒度は以下:

| 直前サイクル                                | 本サイクル相当                                                                                                                                               | 規模             | 並列性               |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------- | -------------------- |
| T1 (qa-design/qa-flow ref+template 新規)    | self-reviewer 関連の **削除タスク群** (skill 本体 / agent / 関連 template / reference の self-review-report.md)                                              | M                | yes (T-削除)         |
| T2 (qa-analyst skill+agent 新規)            | reviewer skill + agent の **責務拡張** (Self-Review 機能の取り込み)                                                                                          | M                | T-削除 後            |
| T3 (dev-workflow/SKILL.md 大規模)           | dev-workflow/SKILL.md 修正 (Step 7 削除 + 番号シフト + Step 6 ↔ Step 7 ループ図削除 + ロールバック早見表更新 + Step 6 ループ表現整理) ※ **サブタスク化推奨** | L → M×3-4 (推奨) | parallel-with T-削除 |
| T4 (planner/implementer/validator I/O 契約) | planner/implementer/validator/architect の入出力欄から Self-Review 関連削除 + 番号シフト                                                                     | M                | yes                  |
| T5 (specialist 番号シフト)                  | architect/intent-analyst/researcher/planner/implementer/validator/retrospective-writer + agents の番号シフト + Self-Review 言及削除                          | S                | yes                  |
| T6 (shared-artifacts schema)                | progress.yaml/templates から `self_review` フィールド削除 + task-plan template の番号シフト                                                                  | M                | yes                  |
| T7 (templates 番号シフト + README)          | TODO.md/retrospective.md template + README 9-step 反映                                                                                                       | S                | yes                  |
| T8 (grep verification)                      | 全成功基準の機械的検証                                                                                                                                       | S                | no (最終)            |

→ **おおむね 8〜10 タスク・3〜4 Wave** が現実的な規模。直前サイクルが 7 時間で完走したことを考えると、本サイクルも同等のスケジュールで完了見込み。

## 残存する不明点

- **本サイクルの Self-Review 機能の External Review への統合方式**: 直前サイクルにはこの種の「責務統合」前例なし。Step 3 Design で他観点 (例: 観点別 reviewer の中の 1 名が Self-Review 役を兼任する案 vs. external reviewer のフロー前段で全 diff 統合レビューを必須化する案) を比較検討すべき。本 Research の責務外。
- **Self-Review 関連ファイル削除に伴う既存サイクル成果物 (本サイクル自身の self-review-report.md) の取り扱い**: 直前サイクルの「過渡期」運用 (新仕様 template と旧仕様成果物の混在) を踏襲できるが、本サイクルは「自分の self-review-report.md をどう扱うか」のメタ問題が発生する。Step 3 Design で確認。
- **直前サイクル retrospective の next-cycle 改善案を本サイクルで何件適用するか**: A-3 で列挙した 5 件はすべて適用する設計が妥当だが、すべて Intent Spec 成功基準に組み込むかは Step 1 で確定。本 Research では「全件適用が望ましい」と推奨するに留める。
- **既存サイクル `docs/dev-workflow/2026-04-26-add-qa-design-step/` の遡及修正不要性**: 直前サイクルの `docs/ai-dlc/2026-04-24-...` 不変ルールと同様に、本サイクルは直前サイクル成果物を不変とすべき。Intent Spec で明示が必要。
