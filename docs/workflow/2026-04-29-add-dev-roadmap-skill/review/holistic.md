# Review Report: holistic

- **Identifier:** 2026-04-29-add-dev-roadmap-skill
- **Aspect:** holistic
- **Reviewer:** reviewer-holistic-round1
- **Reviewed at:** 2026-05-01T21:30:00Z
- **Scope:** 本サイクル Step 6 で生成された全 Git diff (baseline `8444fb4` ↔ HEAD `5fda5a5`、19 コミット) と Intent Spec (14 SC) / design.md (確定 1〜6 + Open Questions) / qa-design.md (TC-001〜TC-033) / task-plan.md (T0〜T12) / `progress.yaml.rollbacks[0]` の整合性。観点別 (security / performance / readability / test-quality / api-design) の深掘りは別 reviewer の担当範囲のため対象外。

## サマリ

| 深刻度  | 件数 |
| ------- | ---- |
| Blocker | 0    |
| Major   | 3    |
| Minor   | 4    |
| Info    | 2    |

**Gate 判定:** `needs_fix` (Major 3 件のうち #1 は本サイクル成果物のスコープ外漏れに起因し設計戻しを伴う可能性、ユーザー判断で Step 3 戻し / Retrospective 繰越のいずれを採るか確定が必要)

## チェックリスト 10 項目の判定サマリ

| # | チェック項目 | 判定 | 関連 Finding |
| - | ------------ | ---- | ------------ |
| 1 | Intent Spec ↔ design (14 SC マッピング) | PASS | — |
| 2 | Design ↔ QA (確定 1〜6 全 TC カバー) | PASS | — |
| 3 | QA ↔ Task Plan (TC-001〜TC-033 全カバー) | PASS | Info-1 |
| 4 | Task Plan ↔ 実装 (T0〜T12 完了 + ファイル整合) | 部分的 PASS | Major-1, Minor-1 |
| 5 | ロールバック追従 (4 起因の Intent → design → 実装伝播) | 部分的 PASS | Major-1 |
| 6 | 未解決事項 6 件の design / 実装での確定 | PASS | — |
| 7 | Open Questions #1 / #2 の実装具体化 | PASS | — |
| 8 | ユーザー指示「dev-workflow → workflow mv を T0」 | PASS | — |
| 9 | Specialist 数 = 3 / agent 数 = 3 / template 4 セット (案 C 確定) | PASS | Minor-3 |
| 10 | 9 ステップ体系: Self-Review 言及の完全除去 | PASS | Info-2 |

## 指摘事項

### #1 (Major) リネーム後 path 置換が `dev-workflow/SKILL.md` / `specialist-common/SKILL.md` / `shared-artifacts/SKILL.md` の 3 ファイル限定で、他 29 ファイルに `docs/dev-workflow/` 表記が 33 箇所残存

- **深刻度:** Major
- **該当箇所:**
  - Commit: 5fda5a5 (実態は T0=2949223 リネーム時点から付随)
  - File: 29 ファイル (内訳: `plugins/dev-workflow/agents/{architect,intent-analyst,planner,qa-analyst,researcher,reviewer,validator}.md` の 7 ファイル / `plugins/dev-workflow/skills/specialist-{architect,implementer,intent-analyst,planner,qa-analyst,researcher,reviewer,validator}/SKILL.md` の 8 ファイル / `plugins/dev-workflow/skills/shared-artifacts/references/{design,implementation-log,intent-spec,progress-yaml,qa-design,qa-flow,research-note,retrospective,review-report,task-plan,todo,validation-report}.md` の 12 ファイル / `plugins/dev-workflow/skills/shared-artifacts/templates/{qa-design,validation-report}.md` の 2 ファイル)
  - Line: 各ファイルで `docs/dev-workflow/<identifier>/...` 表記 (合計 33 箇所、`ggrep -rn "docs/dev-workflow" plugins/dev-workflow/` で観測可能)
- **問題の要約:** Intent Spec L23 (「path 表記は全てリネーム後の新パスを前提とする」) に対し、design.md「既存スキルへの最小変更影響表」(L313-330) と task-plan.md (T8/T9/T10) で path 置換対象を `dev-workflow/SKILL.md` / `specialist-common/SKILL.md` / `shared-artifacts/SKILL.md` の 3 ファイルに限定して計画したため、その他 29 ファイル (agents、特に他 specialist-* SKILL、shared-artifacts/references・templates) の path 表記が `docs/dev-workflow/` のまま放置された。Step 6 implementer はタスク仕様に忠実に動いており、task-plan のスコープ過小が真因。
- **根拠:**
  - 実測: `ggrep -rn "docs/dev-workflow" plugins/dev-workflow/` で 33 件 (3 件の置換対象ファイルではすべて 0 件、置換自体は計画通り実施済)。
  - intent-spec.md:23 「本 Intent Spec 内の path 表記は**全てリネーム後の新パス**を前提とする」と書いてあり、本文中の言及範囲は本サイクルの Intent Spec に閉じるが、design.md L390 では「リネーム後パス基準で diff 0」を成功基準に紐付けて運用上の整合を担保する記述がある。整合のためには references / agents / 他 specialist にも置換が必要。
  - task-plan.md L252 R1 「Step 8 Validation で `ggrep -rn "docs/dev-workflow" plugins/dev-workflow/` を実行して残存箇所が 0 件 (もしくは意図的歴史的記述のみ) であることを確認する」と明文化されているが、これは Validation 段階での観測であり、現状の実装はこの確認を pass しない。
- **推奨アクション:** ユーザー判断で以下のいずれかを選択:
  - (A) **Step 3 設計戻し + 後続伝播** — design.md「既存スキルへの最小変更影響表」に「`agents/*.md` (7 ファイル) / 他 specialist-*/SKILL.md (8 ファイル) / shared-artifacts/{references,templates}/*.md (14 ファイル) の path 一括置換」タスクを追加し、task-plan に T13 (path 機械置換、依存 = T0) を追記、Step 6 implementer に新規インスタンスで T13 のみを担当させる。所要は機械的 sed 置換で S 規模。
  - (B) **本サイクル内で Implementer に追加指示** — Round 2 Step 6 として Main から implementer に「`docs/dev-workflow/` → `docs/workflow/` を `plugins/dev-workflow/` 配下全ファイルで一括置換、historical reference 記述は除外」の追加タスクを発行。task-plan は immutable のため `TODO.md` 後発タスクで管理。
  - (C) **Retrospective 繰越** — 「path 整合性は将来サイクルで一括クリーンアップ」と記録して本サイクルでは触らない。ただし他 SKILL の読者が古いパスを真と誤認するリスクが残る。
- **設計との関連:** design.md「既存スキルへの最小変更影響表」(L313-330) のスコープ過小 / task-plan.md R1 (L252) の Validation チェックが現状未充足 / Intent Spec L23 「path 表記は全てリネーム後の新パスを前提とする」の不完全な実装反映

### #2 (Major) TC-029 / TC-030 の判定基準 (3 名同行列挙) が `ggrep` 行内マッチで fail する形に整形されている

- **深刻度:** Major
- **該当箇所:**
  - Commit: eac161d (T10 specialist-common 追記)
  - File: `plugins/dev-workflow/skills/specialist-common/SKILL.md`
  - Line: L5-7 (frontmatter description 列挙が 3 行に分かれて改行) / L14-17 (Do NOT use for 列挙が 4 行に分かれて改行)
- **問題の要約:** qa-design.md TC-029 / TC-030 の判定基準は `ggrep -nE "(roadmap-analyst.*roadmap-planner.*roadmap-retrospective-writer|roadmap-retrospective-writer.*roadmap-planner.*roadmap-analyst)"` のように **行内マッチ** を要求しているが、実装は YAML 多行 frontmatter の慣例に沿って 3〜4 行に分かれて記述されているため、`ggrep` (デフォルト行内検索) では fail する。実態としては 12 名の列挙は揃っているが、TC が想定する観測手段で pass しない。
- **根拠:**
  - 実測: `ggrep -nE "(roadmap-analyst.*roadmap-planner.*roadmap-retrospective-writer|...)" plugins/dev-workflow/skills/specialist-common/SKILL.md` exit code 1 (no match)。同じく TC-030 の specialist-roadmap-* 同行マッチも exit 1。
  - 実体観測: L5-7 で `intent-analyst, researcher, architect, qa-analyst, planner, implementer,\n  reviewer, validator, retrospective-writer, roadmap-analyst, roadmap-planner,\n  roadmap-retrospective-writer` と 12 名が連続列挙されており、SC-13 自体は満たしている。
  - TC-029 (2) には「または列挙数を別途カウントして 12 個」の OR 条件が書かれているため、Validation 担当者の解釈次第で pass にできるが、`ggrep` 一発判定では検査できない。
- **推奨アクション:** いずれかを採用:
  - (A) **実装側を 1 行化** — frontmatter description の Specialist 列挙を意図的に 1 行に統合し、TC-029 / TC-030 の `ggrep` 一発判定を pass させる。description が長くなるが既存パターン (`dev-workflow/SKILL.md` 等の長文 description) と整合。
  - (B) **TC 判定基準側を多行対応** — `ggrep -nzE` (multiline) または 2 ステップ scenario (先に列挙ブロック行範囲を抽出 → その範囲内で各 name の存在を確認) に書き換え。qa-design.md は immutable 原則だが、Validation 段階で「観測手段の補正」として manual-tests に補足手順を作成する形が現実的。
  - (C) **Validation 担当者に手動代替判定を許容** — TC-029 (2) OR 条件「列挙数を別途カウントして 12 個」を採用、`ggrep -oE 'specialist-(intent-analyst|researcher|architect|qa-analyst|planner|implementer|reviewer|validator|retrospective-writer|roadmap-(analyst|planner|retrospective-writer))' | wc -l` 等のカウント方式に切り替える。
- **設計との関連:** design.md L320 「9 specialists → 12 specialists 更新」の意図と整合 / qa-design.md TC-029 (1) / TC-030 の判定基準が実装ファイル形式と乖離

### #3 (Major) SC-12 関連 TC-017 / TC-026 / TC-027 / TC-028 の `git diff --find-renames` 判定が単一パス指定では rename detection を機能させられず、`0 insertions(+)` を観測できない

- **深刻度:** Major
- **該当箇所:**
  - Commit: 2949223 (T0 リネーム)
  - File: `docs/workflow/2026-04-29-add-dev-roadmap-skill/qa-design.md` (TC-017, TC-026, TC-027, TC-028 の判定基準箇所)
  - Line: TC-017 / TC-028 行 — `git diff --find-renames <baseline>..HEAD -- docs/workflow/<cycle>/` が単一パス指定
- **問題の要約:** qa-design.md TC-017 / TC-028 の判定基準は `git diff --find-renames <baseline>..HEAD -- docs/workflow/<cycle>/` で「内容差分 0」を確認するが、git の rename detection は「source path と destination path の双方が pathspec に含まれる」ことが必要。`docs/workflow/<cycle>/` のみ指定すると、rename source の `docs/dev-workflow/<cycle>/` が pathspec で除外され、すべての成果物が `A` (added、insertions のみ) として観測される (実測: 4 cycle 合計で `+10519 insertions` を観測)。両パスを指定する `git diff --find-renames=50% -- docs/workflow/<cycle>/ docs/dev-workflow/<cycle>/` に書き換えると `0 insertions(+), 0 deletions(-)` が観測できる (実測で確認済)。実体としては内容変更は一切なく SC-12 は満たしているが、TC の観測手段が誤っている。
- **根拠:**
  - 実測: `git diff --find-renames=50% --shortstat 8444fb4..HEAD -- docs/workflow/2026-04-26-add-qa-design-step/` → ` 15 files changed, 1893 insertions(+)` (rename 検出失敗で誤陽性)
  - 同パス対 + old path 指定: ` 15 files changed, 0 insertions(+), 0 deletions(-)` (正しい観測)
  - `git log --oneline 8444fb4..HEAD -- docs/workflow/2026-04-26-add-qa-design-step/ docs/dev-workflow/2026-04-26-add-qa-design-step/` の出力は T0 リネームコミット (2949223) のみで、内容変更コミットは 0 件。
- **推奨アクション:** Validation 担当者向けの観測手段補正として以下を実施:
  - (A) **qa-design.md TC-017 / TC-028 の判定基準を補正** — pathspec を `docs/workflow/<cycle>/ docs/dev-workflow/<cycle>/` の双方を含めるか、`-- .` (全体) + `--diff-filter=M` で「内容変更」のみを抽出する形に変更。qa-design は immutable 原則だが、Validation の TC-IMPL-NNN 領域として補正手順を `manual-tests/TC-017-correction.md` などに追加するのが現実的。
  - (B) **Validation スクリプト側で正しいパス指定を採用** — task-plan.md L252 R1 で言及されている検査スクリプト (`docs/workflow/2026-04-29-add-dev-roadmap-skill/validation-evidence/check-existing-cycle-diff.sh` 等) を Step 8 で実装する際に、両パス指定の正しい invocation を採用する。
  - (C) **Retrospective 繰越** — 「rename detection の落とし穴は将来 QA Design の TC-IMPL 領域に反映」と記録。本 cycle では Validation 担当者がこの脚注を読んで手動補正する前提で進める。
- **設計との関連:** SC-12 / TC-017 / TC-028 の観測手段が git の rename detection 動作と整合しない (qa-design.md L116-120 / L127-128) / 実体としての内容差分 0 は task-plan T0 の `git mv` で達成済 / progress.yaml.rollbacks[0] で示された前提崩壊への追従は実体としては正しく実施されている

### #4 (Minor) design.md L317「ステップ 4 と 5 の間」と実装 L558「ステップ 5 として上書き」の挿入位置が微妙にズレている

- **深刻度:** Minor
- **該当箇所:**
  - Commit: 6b6206b (T9 dev-workflow/SKILL.md 追記)
  - File: `plugins/dev-workflow/skills/dev-workflow/SKILL.md`
  - Line: L558
- **問題の要約:** design.md L317 / L243 では `### 1. ワークフロー開始時` の「ステップ 4 (`progress.yaml` 初期化) と既存ステップ 5 (Step 1 着手) の間」に新規ステップ 4'を挿入する想定だが、実装では「ステップ 5. **roadmap 配下サイクルの場合の追加初期化** (ステップ 4')」として既存ステップ 5 を上書きし、Step 1 着手相当はステップ 6 等に押し下げる構造になっている。TC-018 の判定基準 (`ggrep -nE "ワークフロー開始時"` 配下の段落に roadmap ブロック初期化記述があれば pass) は満たしているため Major には至らない。
- **根拠:**
  - design.md L243-249: 「ステップ 4 と 5 の間」「4'. roadmap 配下サイクルの場合の追加初期化」と表記
  - 実装 L558: 「5. **roadmap 配下サイクルの場合の追加初期化** (ステップ 4')」とラベル付けが「5」に統一されている
  - 機能的には等価で、TC-018 / TC-020 (e) の grep でも検出可能
- **推奨アクション:** Retrospective 繰越。次回類似の挿入時は design 側で「既存ステップ番号を保つか、繰り上げるか」の方針を明示すると implementer の判断負荷が減る。本サイクルでの修正は不要 (機能的等価のため)。
- **設計との関連:** design.md L243 (ワークフロー開始時段落の挿入位置) / SC-7 / TC-018

### #5 (Minor) Self-Review 統合済み 9 ステップ体系の改訂が design.md / 本 task-plan で完全に追従しているが、design.md L518-520 では旧 Step 番号への参照表現が混在 (履歴的説明として意図的)

- **深刻度:** Minor
- **該当箇所:**
  - Commit: 90bb7db (Step 3 design 改訂 post-rollback)
  - File: `docs/workflow/2026-04-29-add-dev-roadmap-skill/design.md`
  - Line: L518-522 (Self-Review 削除と External Review への統合の機械的調整説明)
- **問題の要約:** design.md L518-522 は履歴的説明として「旧 Step 7 Self-Review が担っていた…」「旧 Step 番号 (Step 8 Self-Review / Step 9 External Review / Step 10 Retrospective) は本改訂で全て新 Step 番号 (Step 7 External Review / Step 8 Validation / Step 9 Retrospective) に置換済」と書かれており、これは前提崩壊への追従経緯を retrospective で参照するための意図的記述。読み手が「本 cycle で Self-Review がまだ生きているのでは」と誤解する余地はゼロではないが、文脈で「main マージで統合済」が明示されているため誤読リスクは低い。
- **根拠:**
  - design.md L25-30: 「9 ステップ体系への移行」明記
  - design.md L518-522: 履歴的説明セクション「Self-Review 削除と External Review への統合の影響 (機械的調整)」
  - dev-workflow/SKILL.md (実装後) には Self-Review 関連記述なし、specialist-common 列挙にも `self-reviewer` 不在を確認 (実測で 0 件)
- **推奨アクション:** Retrospective 繰越。本サイクルでの修正は不要。次回類似の前提崩壊時は「履歴的記述ブロック」を視覚的にマーキング (例: > 引用ブロック化) すると将来の誤読リスクをさらに下げられる。
- **設計との関連:** Intent Spec L89 (9 ステップ体系明記) / design.md L25-30 / progress.yaml.rollbacks[0].reason 記述との整合

### #6 (Minor) qa-design.md TC-005 と SC-2 の文言乖離が補注で補強されているが、Intent Spec L108 の本文 (「2 個」) は未改訂

- **深刻度:** Minor
- **該当箇所:**
  - Commit: 6147042 (Intent Spec post-rollback 改訂) / 1f198d2 (qa-design)
  - File: `docs/workflow/2026-04-29-add-dev-roadmap-skill/intent-spec.md`
  - Line: L108 (SC-2 の「2 個」表記)
- **問題の要約:** Intent Spec SC-2 (L108) は「新規 Specialist スキル 2 個の存在」と記載し、design.md 確定 1 (L75 / L347) で案 C 採用 (新設 1 個追加 → 計 3 個) に変わった。qa-design.md L21 で「intent-spec.md L108 の『2 個』は流用前提の暫定値、design.md 確定 1 (L75) により案 C を採用」と明示し、TC-005 で「3 個目を独立 TC で検証」する形に補強しているため、運用上は破綻していない。ただし Intent Spec 本文の数値が古いまま残っているため、初見の読み手は SC-2 と実装 (3 個) の数の食い違いを Intent Spec で検出できない。
- **根拠:**
  - intent-spec.md L108: 「**新規 Specialist スキル 2 個の存在**」
  - design.md L347: 「案 C: `specialist-roadmap-retrospective-writer` 新設 — 採用」
  - qa-design.md L21-23: SC-2 / SC-3 / SC-4 すべてで「intent-spec.md の数値は流用前提の暫定値、design.md 確定 1 で X 個に拡張」と補注
  - 実装: `specialist-roadmap-{analyst,planner,retrospective-writer}` 3 ファイル + agent 3 ファイル + template/reference 4 セット (実測一致)
- **推奨アクション:** Retrospective 繰越。本サイクルでの Intent Spec 改訂はユーザー承認ゲートを再度トリガーするためコスト高。次回類似の design 段階での数値変更が発生した場合は、Intent Spec の即時改訂 + 再ゲートか、qa-design 補注で対処するかを Main が運用ルールとして確定するのが望ましい。本サイクルでは qa-design 補注で十分整合済。
- **設計との関連:** Intent Spec SC-2 / SC-3 / SC-4 と design.md 確定 1 (案 C) の数値乖離 / qa-design.md L21-23 の補注で実装と整合

### #7 (Minor) progress.yaml が `current_step: 'Step 7: External Review'` のままで、本レビュー完了後の Step 7 完了反映が pending

- **深刻度:** Minor (Info に近い、レビュー進行中の状態として正常)
- **該当箇所:**
  - Commit: 5fda5a5 (Step 6 完了)
  - File: `docs/workflow/2026-04-29-add-dev-roadmap-skill/progress.yaml`
  - Line: L6 (`current_step: 'Step 7: External Review'`)
- **問題の要約:** Step 6 完了コミット時点で `current_step` を Step 7 に進め、Step 6 を `completed_steps` に追加済 (L41-46)。本ファイル (`review/holistic.md`) と他観点 reviewer の出力が揃った時点で `progress.yaml.review` (L67) に Round 1 集計を反映する想定。Specialist 自身は commit しない方針 (specialist-common §7) のため、これは Main の Step 7 集約タスク。レビュー進行中として正常な状態。
- **根拠:** progress.yaml L5-6 / L8-46 で Step 6 完了 + Step 7 進行中を表現、L67 `review: []` は Step 7 集約待ち
- **推奨アクション:** Main が Step 7 完了時に `progress.yaml.review` に Round 1 集計 (各観点の Blocker/Major/Minor 件数 + ファイルパス) を反映してコミット。本レビューでは記載のみ、変更不要。
- **設計との関連:** dev-workflow/SKILL.md L411 holistic 観点定義 / progress.yaml schema (L67 review)

## 観点固有の評価項目

### 全体整合性チェック (Round 1 必須項目)

- **Intent Spec ↔ design.md 整合性 (チェック 1):** PASS。SC-1〜SC-14 すべてが design.md「コンポーネント構成」(L66-94) / 「`roadmap-progress.yaml` スキーマ詳細」(L162-231) / 「`dev-workflow/SKILL.md` への追記内容草稿」(L233-309) / 「既存スキルへの最小変更影響表」(L311-330) / 「Open Questions」(L539-573) のいずれかにマッピングされている。SC-2 / SC-3 / SC-4 の数値乖離 (流用 → 案 C 確定) は qa-design 補注 + design 確定 1 で整合済 (Minor-3 に記録)。
- **Design ↔ QA 整合性 (チェック 2):** PASS。design 確定 1 (案 C 新設) → TC-005 で具体検証 / 確定 2 (案 A 統合) → TC-029 + TC-030 / 確定 3 (独立トップレベル ##) → TC-019 / 確定 4 (graph LR 採用) → 直接 TC は無いが design 内で記述 / 確定 5 (シンプルマージ) → TC-024 (3 観点に「3-way / set union」明記要求) / 確定 6 (再開プロトコル流用 5 + 修正 3 + 新規 4) → dev-roadmap/SKILL.md 内の独立セッション再開時セクションで実装 (実測 L355 周辺で確認可能、TC では明示検証なし)。
- **QA ↔ Task Plan 整合性 (チェック 3):** PASS。task-plan.md L274-308 のカバレッジ表で TC-001〜TC-033 の全 33 件が少なくとも 1 タスクでカバーされている。
- **Task Plan ↔ 実装整合性 (チェック 4):** 部分的 PASS。T0〜T12 の 13 タスク全てが TODO.md で `[x]` 完了済 (実測)。新規 14 ファイル + 既存追記 6 ファイルが diff 上で確認できる (実測 76 ファイル変更 = リネーム 64 + 新規/追記 12)。**ただし Major-1 で指摘した path 置換のスコープ過小により、29 ファイルで `docs/dev-workflow/` 表記が残存**。task-plan の T0/T8/T9/T10 計画自体は完遂しているが、計画スコープが Intent Spec L23 を網羅していない。
- **ロールバック追従整合性 (チェック 5):** 部分的 PASS。`progress.yaml.rollbacks[0]` の 4 起因 (9 ステップ移行 / docs/workflow + docs/roadmap rename / retrospective 集約 / 成功基準 #12 ベースライン再定義) は (i) Intent Spec L89 / L23 / L72-73 / L118 で改訂、(ii) design.md L25-30 / L60 / L57 / L14 で改訂、(iii) 実装で正しく反映 — ただし path rename (T0) は実体としては全完了だが、本文中の path 表記置換が 3 ファイル限定でスコープ過小 (Major-1 と同根)。残り 3 起因はすべて完全追従。
- **未解決事項 6 件の確定 (チェック 6):** PASS。Intent Spec 未解決事項 #1 (Specialist 列挙統合) → design 確定 2 案 A / #2 (再開プロトコル) → design 確定 6 / #3 (Mermaid 記法) → design 確定 4 graph LR / #4 (競合回避) → design 確定 5 案 A 修正 / #5 (retrospective 流用) → design 確定 1 案 C / #6 (dev-workflow セクション挿入位置) → design 確定 3 独立トップレベル / #7 (retrospective 命名衝突) → design Open Questions #1 で `roadmap-` prefix 確定。すべて design.md / 実装で具体化済。
- **Open Questions 確定の実装具体化 (チェック 7):** PASS。Open Questions #1 (`roadmap-` prefix) は実装で明文化 (`dev-roadmap/SKILL.md` L243 / L248 / L405-407、`shared-artifacts/references/roadmap-retrospective.md` L22 / L31 / L125 / L139、`shared-artifacts/SKILL.md` L158 で重複明記、TC-033 の grep で pass)。Open Questions #2 (roadmap-retrospective テンプレート) は T7 で `templates/roadmap-retrospective.md` (118 行) + `references/roadmap-retrospective.md` (141 行) を新規作成 (実測)。
- **ユーザー指示 G0 先行 (チェック 8):** PASS。T0 (commit 2949223 `chore(workflow): rename docs/dev-workflow/ to docs/workflow/ and add docs/roadmap/ (T0)`) が Step 6 全タスクの最初のコミットとして単独実施され、リネームのみで内容変更ゼロ (`git show --stat 2949223` 確認、後続コミットの依存)。
- **Specialist 数 = 3 / agent 数 = 3 / template/reference 数 = 4 セット (チェック 9):** PASS。実測: `plugins/dev-workflow/skills/specialist-roadmap-{analyst,planner,retrospective-writer}/SKILL.md` 3 件 + `plugins/dev-workflow/agents/roadmap-{analyst,planner,retrospective-writer}.md` 3 件 + `shared-artifacts/{templates,references}/roadmap{,.md},milestone.md,roadmap-progress{.yaml,-yaml.md},roadmap-retrospective.md` の 4 セット (template 4 + reference 4 = 8 ファイル)。Intent Spec L41 で「retrospective-writer 流用 → Step 2 Research で検証 → 流用不可なら新規」と書かれた予定分岐は、Research `retrospective-writer-reusability.md` で「F1: workflow 単位前提」「F2: 入力契約乖離」を発見し案 C に確定 (design L347)、実装は案 C に整合。
- **9 ステップ体系の整合 (チェック 10):** PASS。実測: `plugins/dev-workflow/` 配下に `self-reviewer` / `Self-Review` / `specialist-self-reviewer` の **本文残存ゼロ** (本サイクル新規ファイル + 既存 SKILL/dev-workflow) を確認。本サイクル成果物 (intent-spec/design/qa-design/task-plan/progress.yaml) では Self-Review に関する言及はすべて「main マージで統合済」「本サイクルでは扱わない」「Step 7 External Review」の文脈で履歴的に記録。`progress.yaml.self_review: null  # ステップ廃止 (9 ステップ体系)` (L66) も 9 ステップ体系に整合。

## 修正ラウンド履歴

| Round | Blocker | Major | Minor | 主要指摘 (要約) | 修正コミット SHA |
| ----- | ------- | ----- | ----- | --------------- | ---------------- |
| 1     | 0       | 3     | 4     | path 置換スコープ過小 (Major-1) / TC-029-030 観測手段不整合 (Major-2) / SC-12 観測手段不整合 (Major-3) | (Round 1、修正未着手) |

Round 2 以降が必要かどうかはユーザー判断。Major 3 件のうち Major-1 のみ実装変更を伴う、Major-2 / Major-3 は判定基準補正で対応可能。

## 他レビューとの整合性

- なし (Round 1、holistic 観点は他観点 reviewer の出力前提で動かないため、現時点では矛盾検出対象なし)。
- Round 2 以降で security / performance / readability / test-quality / api-design 観点の reviewer 出力が揃った場合、本 holistic は当該レポートをクロスリファレンス可能 (specialist-reviewer SKILL.md L52-53 のループ運用に従う)。

## 補足: Info 級の観察事項 (将来 retrospective 材料)

- **Info-1:** qa-design.md は TC-001〜TC-033 の 33 TC を network 1 件 (TC-IMPL-NNN は 0 件) で構成し、SC-12 を最も TC 数が多い 4 件 (TC-017 / TC-026 / TC-027 / TC-028) でカバーするなど、SC ↔ TC の数の偏り (SC-7 = 1 件 vs SC-6 = 4 件) が観察可能。各 TC の重要度 (Blocker → Validation での fail-fast / Minor → 周辺観察) を区分するメタデータが将来の Validation 効率化に寄与する可能性がある。
- **Info-2:** 本サイクルは companion サイクル `2026-04-29-integrate-self-review-into-external` (Self-Review → External Review 統合) と `2026-04-29-retro-cleanup` (retrospective 集約化) の両方が main マージされた直後にロールバックを経験した。複数 companion を並行進行させた際の前提崩壊リスクは retrospective で議論する材料になりうる (本サイクル design.md L395 でも触れている)。
