# Review Report: readability

- **Identifier:** 2026-04-29-integrate-self-review-into-external
- **Aspect:** readability
- **Reviewer:** reviewer-readability-r1
- **Reviewed at:** 2026-04-29
- **Scope:** 本サイクルで変更された `plugins/dev-workflow/` 配下の Markdown / JSON / YAML（SKILL.md 群、agents/\*.md、shared-artifacts の references / templates、README.md、plugin.json）。Self-Review 削除に伴う読みやすさ・整列・用語一貫性・リンク健全性に限定し、security / performance / api-design / test-quality / holistic は対象外。

## サマリ

| 深刻度  | 件数 |
| ------- | ---- |
| Blocker | 0    |
| Major   | 4    |
| Minor   | 6    |

**Gate 判定:** needs_fix

Major 4 件は記述上の不整合（用語の残骸、placeholder 名と本文の不一致、テーブル整列崩れ）であり、文書の読み手が誤解する可能性がある。Blocker は検出されなかったため Step 6 への差し戻しは不要だが、ユーザー承認前に Major を修正するか、Retrospective 繰越とするかの判断が必要。

## 指摘事項

### #1 `main-*` スキル参照の残骸（削除漏れ）

- **深刻度:** Major
- **該当箇所:**
  - Commit: 2ea101d (Self-Review removal across specialists)
  - File: `plugins/dev-workflow/skills/shared-artifacts/SKILL.md`
  - Line: 10
  - File: `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md`
  - Line: 56
- **問題の要約:** 本プラグインには `main-*` という名前のスキルは存在せず、`dev-workflow` スキル 1 本に統合されている。にもかかわらず 2 箇所で `main-*` という存在しないスキル名を参照している。
  - `shared-artifacts/SKILL.md:10` → 「Do NOT use for: ワークフロー手順（main-\* スキル）」
  - `references/retrospective.md:56` → 「dev-workflow プラグインのスキル（`main-*` / `specialist-*` / `shared-artifacts`）への具体的な改善提案」
- **根拠:** 読者が `main-*` という別カテゴリのスキル群が存在すると誤認する。実態は `dev-workflow` 単独であり、`templates/retrospective.md:58` では既に `dev-workflow` / `specialist-*` / `shared-artifacts` と正しい名前で書かれている（reference と template が乖離している）。
- **推奨アクション:**
  - `shared-artifacts/SKILL.md:10` を「ワークフロー手順（`dev-workflow` スキル）」に変更
  - `references/retrospective.md:56` を「`dev-workflow` / `specialist-*` / `shared-artifacts`」に変更（template と一致させる）
- **設計との関連:** `design.md` の Self-Review 統合方針において、スキル一覧は `dev-workflow` / `specialist-*` / `shared-artifacts` の 3 系統で確定済み。`main-*` は旧構成の残骸。

### #2 Retrospective テンプレートの placeholder 名がステップ番号とずれている

- **深刻度:** Major
- **該当箇所:**
  - Commit: 770907b (renumber step tables and ASCII flow to 9-step layout)
  - File: `plugins/dev-workflow/skills/shared-artifacts/templates/retrospective.md`
  - Line: 36, 92
- **問題の要約:** ステップ 9 体系へのリネーム後、placeholder 名がアップデートされていない。
  - line 36: `| Step 6 ↔ Step 7   | {{loop_5_6}}      | {{root_cause_5_6}}  |` — 表ラベルは「Step 6 ↔ Step 7」だが placeholder 名は `loop_5_6` / `root_cause_5_6`（5 と 6 のループ＝旧体系の名残）
  - line 92: `- Step 5 (Task Decomposition): {{gate_4_summary}}` — Step 5 を表すのに placeholder は `gate_4_summary`
- **根拠:** retrospective-writer が template を埋める際、placeholder の数字とステップ番号が一致しない。書き間違いを誘発し、読者にも混乱を与える。`references/retrospective.md:38` には `{{n}}` という抽象 placeholder で書かれているのに対し、template 側だけが旧番号を引き摺っている。
- **推奨アクション:**
  - line 36: `{{loop_5_6}}` → `{{loop_6_7}}`、`{{root_cause_5_6}}` → `{{root_cause_6_7}}`（または reference に揃えて `{{n}}` / `{{root_cause}}`）
  - line 92: `{{gate_4_summary}}` → `{{gate_5_summary}}`
- **設計との関連:** `design.md` の「ステップ番号統一」方針に従い、表ラベル・本文・placeholder すべてを同一番号体系で整える必要がある。

### #3 Retrospective テンプレートに Step 4 (QA Design) のユーザー承認ゲートが抜けている

- **深刻度:** Major
- **該当箇所:**
  - Commit: 770907b (renumber step tables and ASCII flow to 9-step layout)
  - File: `plugins/dev-workflow/skills/shared-artifacts/templates/retrospective.md`
  - Line: 90-94
- **問題の要約:** ユーザー承認ゲート振り返りリストに Step 4 (QA Design) が含まれていない。本ワークフローでは Step 4 もユーザー承認必須（`dev-workflow/SKILL.md:277` Gate: ユーザー承認必須）と定義されているにもかかわらず、template が以下のように飛ばしている:

  ```
  - Step 1 (Intent Clarification): {{gate_1_summary}}
  - Step 3 (Design): {{gate_3_summary}}
  - Step 5 (Task Decomposition): {{gate_4_summary}}   ← Step 4 が抜けている
  - Step 7 (External Review): {{gate_7_summary}}
  - Step 8 (Validation): {{gate_8_summary}}
  ```

- **根拠:** retrospective-writer が template を素直に埋めると、本サイクルから新たに追加された QA Design 承認ゲートの振り返りが恒常的に欠落する。
- **推奨アクション:** `Step 3 (Design)` と `Step 5 (Task Decomposition)` の間に `- Step 4 (QA Design): {{gate_4_summary}}` を追加。続く Step 5 の placeholder は #2 で指摘した通り `{{gate_5_summary}}` に直す。
- **設計との関連:** `design.md` のステップ別ゲート定義（Step 4 は User、Step 2 / Step 6 / Step 9 は Main）。

### #4 並列起動のガイドラインのテーブル幅が大幅に崩れている

- **深刻度:** Major
- **該当箇所:**
  - Commit: edc76ad (replace Step 7 Self-Review with absorbed External Review)
  - File: `plugins/dev-workflow/skills/dev-workflow/SKILL.md`
  - Line: 756-766
- **問題の要約:** Step 6 / 7 / 8 / 9 行（line 763-766）の 3 列目「並列軸」が他行と比べて極端に長く、列幅が揃っていないためテーブル崩れが起きている。具体的に line 763 は 71 文字、line 764 は 100 文字超で、line 757-762 の罫線（`| -------------- |`）と整合しない。
- **根拠:** Markdown テーブルとしては動作するが、ソース閲覧時に読みづらく、編集時に行揃えが乱れる。元々 5 ステップ体系時代の幅で作られた表に、6 観点 (security/performance/readability/test-quality/api-design/holistic) を 1 行に詰め込んだことが原因。
- **推奨アクション:** いずれかを採用:
  1. line 764 の「6 観点並列」内訳を本文の Step 7 セクションに退避し、テーブルでは「レビュー観点ごと（6 並列）」と要約する
  2. テーブル全体を再フォーマットして罫線を最長行幅に揃える（line 757 の `| ----- |` 等を再生成）
- **設計との関連:** ASCII / Markdown 表の整列は読みやすさ規律として全 SKILL.md で揃えており、本箇所のみ逸脱している。

### #5 Retrospective reference のループテーブルに重複行が含まれる

- **深刻度:** Minor
- **該当箇所:**
  - Commit: 770907b
  - File: `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md`
  - Line: 38-39
  - File: `plugins/dev-workflow/skills/shared-artifacts/templates/retrospective.md`
  - Line: 36-38
- **問題の要約:** template の line 38 に `| Step 7 → Step 6   | {{rollback_v_c}}  | {{root_cause_v_c}}  |` という行があり、これは line 36 の「Step 6 ↔ Step 7」と意味的に重複している（双方向矢印 ↔ の中に Step 7 → Step 6 が含意される）。reference の line 38-39 では正しく「Step 6 ↔ Step 7」「Step 6/7 → Step 3」の 2 行構成だが、template には余計な 3 行目が残っている。
- **根拠:** Self-Review 削除前の旧体系では「Self-Review (旧 Step 7) → Implementation (旧 Step 6)」のような独立した方向性のループがあり、その置換が完全でない可能性が高い。retrospective-writer が混乱して同じ事象を 2 行に分けて書く危険がある。
- **推奨アクション:** template の line 38 を削除。reference と同じ 2 行構成（Step 6 ↔ Step 7 / Step 6/7 → Step 3）に揃える。
- **設計との関連:** ループ図 (`dev-workflow/SKILL.md:447-473`) で示される唯一の主要ループは Step 6 ↔ Step 7 のみ。

### #6 specialist-reviewer SKILL.md の description が長く、改行で句読点が分断されている

- **深刻度:** Minor
- **該当箇所:**
  - Commit: 2ea101d
  - File: `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md`
  - Line: 4-16
- **問題の要約:** description の line 5-6 で `security / performance / readability / test-quality` までで改行し、`/ api-design / holistic の 6 観点が起点）` が次行に来るため、自動列挙の途中で改行が入る。同様に line 12 が単独の長文（160 文字超）で、frontmatter description の典型的な長さを超えている。
- **根拠:** description はスキル発火条件のメタデータで、表示時に丸ごと文字列として連結される。読み手の検索性・スキャン性に影響する。他スキル（例: `specialist-implementer/SKILL.md:3-11`）は description が 9 行以内に収まっており、本スキルだけ 13 行と突出している。
- **推奨アクション:** description を 9〜10 行程度に短縮（例: 「`security / performance / readability / test-quality / api-design / holistic` の 6 観点」と一行で記述、起動トリガーの観点列挙も簡潔化）。
- **設計との関連:** スキル description の長さ規律は `dev-workflow` プラグイン全体で `specialist-*` 共通の慣習がある。

### #7 specialist-reviewer SKILL.md の Do NOT use 句から `specialist-self-reviewer` 排除文言が抜けた点の整合性

- **深刻度:** Minor
- **該当箇所:**
  - Commit: 2ea101d
  - File: `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md`
  - Line: 14-16
- **問題の要約:** description の `Do NOT use for:` 節に「自己レビュー（specialist-self-reviewer、全観点統合の事前レビュー）」のような旧来の対比文言は無くなっているが、specialist-common SKILL.md (line 6-7, 13-15) では Specialist 一覧に `self-reviewer` が**既に存在しない**形に正しく更新されている。一方で本スキルの description には統合経緯（「holistic 観点が旧 Self-Review 機能を吸収した」等）が一切触れられず、新規読者に統合の意図が伝わらない。
- **根拠:** Retrospective や次サイクルの reviewer-writer が「holistic = 旧 Self-Review の継承先」を理解できず、責務範囲を誤解する可能性がある。本サイクルの目的が「Self-Review を External Review に統合」である以上、その経緯を 1 行で示すと混乱が減る。
- **推奨アクション:** specialist-reviewer SKILL.md の本文「役割」セクション冒頭に「holistic 観点は旧 Self-Review が担っていた全体整合性チェックを継承している」のような 1 文を追加。description には不要だが本文に明示する。
- **設計との関連:** `design.md` の「Self-Review を holistic 観点として External Review に統合」方針。

### #8 qa-flow.md reference のテーブルが致命的に崩れている（Self-Review 削除と無関係だが本サイクル diff 範囲内に存在）

- **深刻度:** Minor
- **該当箇所:**
  - Commit: 削除以前から存在（本サイクルでは未修正）
  - File: `plugins/dev-workflow/skills/shared-artifacts/references/qa-flow.md`
  - Line: 88-93
- **問題の要約:** 「矢印（エッジ）」の Markdown テーブルが破損している:

  ```
  | 構文       | 意味                |
  | ---------- | ------------------- | --- | ----------------------------------- |
  | `A --> B`  | 通常の遷移          |
  | `A -->     | label               | B`  | ラベル付き遷移 (条件分岐の値を記述) |
  | `A -.-> B` | 点線 (オプショナル) |
  | `A ==> B`  | 太線 (主要パス強調) |
  ```

  - line 88 のヘッダ行は 2 列だが、line 89 の罫線は 4 列分書かれている
  - line 91 の `A -->|label| B` を表現するために `|` を 3 つ使ったため、Markdown が 4 列として解釈されてしまう

- **根拠:** GitHub の Markdown レンダラ上で表が壊れて表示される。Self-Review 削除サイクルの直接修正対象ではないが、本観点（テーブル整列・読みやすさ）のスコープ内で発見した既存欠陥。
- **推奨アクション:**
  - ヘッダを 2 列で統一: `| 構文 | 意味 |`
  - `A -->|label| B` の行は構文部をバッククォートで全体エスケープし、`| `` `A -->\|label\| B` `` | ラベル付き遷移... |` のように記述
  - もしくは表ではなく箇条書きで再表現
- **設計との関連:** 本サイクルの直接の責務外だが、Retrospective でリスト化を推奨。

### #9 dev-workflow.md ステップ一覧表の Specialist 列に全角スペースが揺れている

- **深刻度:** Minor
- **該当箇所:**
  - Commit: 770907b / edc76ad
  - File: `plugins/dev-workflow/skills/dev-workflow/SKILL.md`
  - Line: 125-135
- **問題の要約:** ステップ一覧表は概ね揃っているが、`Specialist (起動形態)` 列の値で `× 1`（半角）と `× N (並列)` のように半角・全角の混在は無いものの、行ごとに「（並列）」と「（タスク並列）」「（6 観点並列）」の表記が一定ルールに従っていない（並列形態の説明が冗長 / 簡潔混在）。
- **根拠:** 厳密には用語不統一。読者が「並列」「タスク並列」「6 観点並列」を別概念と誤解する余地。
- **推奨アクション:** 並列軸を統一表記に揃える:
  - 単独 → `× 1`
  - 観点並列 → `× N (観点並列)`
  - タスク並列 → `× N (タスク並列)`
  - 6 観点並列は「観点並列」と統一しつつ、本文で「6 観点固定」と詳細補足
- **設計との関連:** Specialist 起動形態は dev-workflow.md の「並列起動のガイドライン」(line 754-766) と一貫させるべき。

### #10 specialist-retrospective-writer SKILL.md の作業手順 5 で markdown 強調記法が壊れている

- **深刻度:** Minor
- **該当箇所:**
  - Commit: 削除以前から存在（本サイクルでは未修正）
  - File: `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md`
  - Line: 73-75
- **問題の要約:** 作業手順 5 のサブ箇条書きで `main-_ / specialist-_` という記述があり、本来は `main-* / specialist-*`（アスタリスクのワイルドカード）のところを、Markdown の italic 記法 `_..._` に誤って解釈されてエスケープされている。
  ```
  - スキル改善（main-_ / specialist-_ スキルの具体的変更提案）
  ```
- **根拠:** ソースを読んでも HTML レンダリング後を読んでも意味が取りづらい。さらに `main-*` 自体が #1 の指摘通り存在しないスキル名なので、二重の問題。
- **推奨アクション:** `main-_ / specialist-_` を削除し、「`dev-workflow` / `specialist-*` スキルの具体的変更提案」と書き換える。
- **設計との関連:** #1 と同根の修正。

## 観点固有の評価項目

- **命名の一貫性:** Self-Review 削除に伴う名残が `main-*` 参照（2 箇所）と placeholder 名（`loop_5_6` / `gate_4_summary`）に残存。それ以外は概ね整理されている。
- **責務分離の明示性:** specialist-reviewer SKILL.md の役割定義は明瞭。ただし holistic 観点が旧 Self-Review を吸収した経緯が本文に記載されておらず、責務範囲の意図が新規読者に伝わりにくい（指摘 #7）。
- **コメント品質:** YAML / Markdown コメントは観測した範囲で問題なし。`templates/progress.yaml` の inline コメントは丁寧。
- **型・enum の表現:** `<aspect>` ∈ {`security`, ..., `holistic`} の集合表記は specialist-reviewer SKILL.md・dev-workflow.md・shared-artifacts/SKILL.md・review-report reference 全てで一貫。
- **章節階層:** 見出しの飛びは検出されず（h1 → h2 → h3 の自然な階層）。
- **ASCII 図:** dev-workflow.md line 99-119 のフロー図、line 447-473 のループ図ともに整列良好。Mermaid 図は qa-flow reference の構文例として使われており、本サイクル diff の範囲では新規 Mermaid は無し。
- **frontmatter description の長さ:** specialist-reviewer SKILL.md (13 行) のみ他スキル（9 行前後）より長い。指摘 #6 として記録。
- **削除された Self-Review の文脈跡:** `self-review` / `Self-Review` / `specialist-self-reviewer` の grep ヒットは 0 件で、直接的な参照は完全削除されている。間接的な残骸は #1, #2, #5, #10 の 4 件。
- **リンク切れ:** 内部相対パスは全て生存ファイルを指している。`shared-artifacts/references/review-report.md` 等の参照は全て有効。

## 他レビューとの整合性

- なし（Round 1 のため他 reviewer 出力は未参照、独立並列実施）

矛盾・重複が発生する可能性のある観点と境界:

- holistic 観点との重複懸念: 「Step 4 ゲート振り返り抜け」（指摘 #3）は holistic も「全体整合性」として検出する可能性がある。ただし本観点では「retrospective テンプレ自体の文書としての完成度」を理由に Major としており、責務範囲は守っている。
- api-design 観点との境界: placeholder 名（`gate_4_summary` 等）は API 契約ではなく文書テンプレ上の命名規律なので readability スコープと判定。
