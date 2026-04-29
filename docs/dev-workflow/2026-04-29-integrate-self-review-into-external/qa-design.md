# QA Design: Integrate Self-Review (Step 7) into External Review

- **Identifier:** 2026-04-29-integrate-self-review-into-external
- **Author:** qa-analyst (Specialist instance #1)
- **Source:** `intent-spec.md`, `design.md`
- **Created at:** 2026-04-29T15:00:00Z
- **Last updated:** 2026-04-29T15:00:00Z
- **Status:** draft <!-- draft | approved -->

このドキュメントは **Step 4 で確定する本質テスト設計**。Step 6 (Implementation) で implementer が「実装段階で発見されたテスト」を `TC-IMPL-NNN` として追記する。書き方の詳細は `plugins/dev-workflow/skills/shared-artifacts/references/qa-design.md` を参照。

## 概要

`intent-spec.md` の成功基準 17 件は既に「コマンドで観測可能な静的事象」として記述されているため、本ドキュメントでは各成功基準を **そのまま `SC-N` として継承し**、対応する本質テストケース `TC-NNN` に 1:1 マッピングする。本サイクルは `dev-workflow` プラグインの Markdown 成果物のみを対象とする meta-reflexive サイクルであり、実行可能コードを含まない。検証は **静的観測**（ファイル存在 / `grep` 件数 / 行数 / Markdown 構造の目視）に限定される。

成功基準の整理（intent-spec.md L121–L152 より転記）:

### 削除確認 (4 件)

- **SC-1**: `test ! -d plugins/dev-workflow/skills/specialist-self-reviewer` が真（ディレクトリ非存在）
- **SC-2**: `test ! -f plugins/dev-workflow/agents/self-reviewer.md` が真
- **SC-3**: `test ! -f plugins/dev-workflow/skills/shared-artifacts/templates/self-review-report.md` が真
- **SC-4**: `test ! -f plugins/dev-workflow/skills/shared-artifacts/references/self-review-report.md` が真

### 残存表記の根絶 (4 件)

- **SC-5**: `grep -rnE -i 'self[-_]review|Self-Review' plugins/dev-workflow/` が **0 件**
- **SC-6**: `grep -rnE 'self-reviewer|specialist-self-reviewer' plugins/dev-workflow/` が **0 件**
- **SC-7**: `grep -rnF 'Step 10' plugins/dev-workflow/` が **0 件**
- **SC-8**: `grep -rnE 'Step 9 \(Validation\)|Step 10 \(Retrospective\)' plugins/dev-workflow/` が **0 件**（旧番号でのステップ参照表記は不在）

### 構造的完全性 (5 件)

- **SC-9**: `plugins/dev-workflow/skills/dev-workflow/SKILL.md` のステップ一覧テーブルが 9 行で、Step 7 が `External Review` / `reviewer × N (観点並列)` / Gate=Main / 主要成果物に `review/<aspect>.md` を持つ
- **SC-10**: 同 SKILL.md のロールバック早見表に Step 7 (External Review)、Step 8 (Validation)、Step 9 (Retrospective) のエントリが存在し、旧 Self-Review 由来のエントリは External Review に統合されている
- **SC-11**: `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` 本文に「全体整合性」または「整合性」キーワードが検出される
- **SC-12**: `plugins/dev-workflow/skills/shared-artifacts/SKILL.md` の成果物一覧テーブルから `self-review-report.md` 行が削除され、行番号が連番（欠番なし）で再付番されている
- **SC-13**: `plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml` から `self_review:` フィールドが削除されている（`grep -nE '^\s*self_review:'` が 0 件）

### メタ整合性 (4 件)

- **SC-14**: `plugins/dev-workflow/README.md` が 9-step 構成と 9 specialist subagents を反映（specialist 数の数値・ステップ列挙が一貫）
- **SC-15**: `plugins/dev-workflow/.claude-plugin/plugin.json` の description が 9-step 構成かつ Self-Review 言及なし
- **SC-16**: `plugins/dev-workflow/agents/` 配下に 9 ファイル存在し（`self-reviewer.md` 削除後）、各 description / 本文に Self-Review 言及がない
- **SC-17**: dev-workflow / specialist-\* スキル内のクロスリファレンス（`specialist-self-reviewer` / `self-review-report.md` 等）が他の現存スキル名 (`specialist-reviewer` / `review/<aspect>.md`) で正しく置換されており、リンク切れが新規発生していない（手動目視確認）

すべての成功基準が **観測可能** であるため、qa-analyst からの Blocker 報告は不要（Intent Spec のロールバック判断を仰ぐ条件は満たさない）。

## 自動 vs 手動の判断方針

本サイクルは **Markdown / JSON / YAML のみが変更対象** であり、実行可能コード（TypeScript / MoonBit / Go 等）を含まない。したがって従来の「Vitest / Playwright で `automated × scenario` を組む」パターンは適用外で、検証手段は次の 2 種類に大別される。

1. **`automated × *`（CI で機械実行可能な静的検査）** — `test`, `grep -rnE/F`, `find`, `wc -l`, `ls`, `gsed -n` といった POSIX 系コマンドで合否判定が完結するもの。`existence`（ファイル / ディレクトリの有無）、`count`（grep 件数の数値判定）、`structural`（行数 / カラム数 / 連番性のような構造的観測）の 3 つの **検証スタイル** に細分化する。Step 8 Validation で validator が確定コマンドセット（design.md L438–L494）を実行し、validation-report.md にログを記録することで全件再現性が確保される。
2. **`manual × inspection`（人間目視判断）** — 「クロスリファレンスのリンク切れ」「ステップ表テーブルの記載内容が新フローと意味的に整合しているか」「ロールバック早見表のエントリが旧 Self-Review 由来の知見を吸収できているか」「ステップ番号テーブルの「Step 7 = External Review / reviewer × N」のセル値が design.md と一致しているか」のような **意味的整合性** を扱うもの。grep では検出できない（検出できれば automated 化する）。本サイクルでは SC-9 / SC-10 / SC-12 / SC-14 / SC-17 が該当。

軸 A の振り分け原則は **「`grep` で機械的に件数判定可能なら automated、内容の意味解釈が必要なら manual`」**。軸 B は「ファイル単位の存在 → `existence`」「複数行の件数判定 → `count`」「ファイル内構造（行数 / カラム / 連番）の観測 → `structural`」「人間の意味判断が必要 → `inspection`」と機能分解する。

**禁止組み合わせ `automated × inspection` は本サイクルでは発生しない**（automated は機械判定、inspection は人間判定の意で本質的に矛盾するため、本仕様では `manual × inspection` のみ採用）。`manual × structural` は意味的判断と構造的観測が同時に必要なケース（例: ステップ表のセル内容が意味的に正しいかを確認する際、行数自動カウント + 各行の意味目視）に採用する。

`ai-driven` 軸は本サイクルでは採用しない。Markdown 成果物の検査に AI ブラウザ操作や AI 動的判断は不要で、`automated` か `manual` の二択で十分。

## テストファイル配置ポリシー

本サイクルは「テストファイル」というアーティファクトを生まず、`automated` テストはすべて **Step 8 Validation の validator が実行する `bash` コマンドセット** として `validation-report.md` に記録される。`manual` テストは **手順書を本ドキュメント内（`本質テストケース` セクションの `判定基準` 列）に直接記述する** 方式で扱う（手順書を別ファイル化すると保守箇所が増えるため、テストケース 17 件規模なら本ドキュメント内で十分）。

具体配置方針:

- `automated × existence`: `validation-report.md` のコマンドログに `test -d`, `test -f`, `test ! -d`, `test ! -f` の終了コード 0/1 を記録
- `automated × count`: `validation-report.md` のコマンドログに `grep -rnE/F ... | wc -l` または `grep -c ...` の数値結果を記録
- `automated × structural`: `validation-report.md` のコマンドログに `wc -l`, `ls | wc -l`, `gsed -n '...p' | wc -l` 等の数値判定結果を記録
- `manual × inspection`: 本ドキュメント内 `判定基準` 列に手順を箇条書きで記述。validator は人間（または Main エージェント）として手順を実行し、結果を `validation-report.md` に「OK / NG + 根拠 1 行」で記録
- `manual × structural`: 上記 `manual × inspection` と同形式だが、観測対象が構造的（行数 / 連番 / セル値）であるため、判断の客観性が高い

具体的なファイルパス（validator がコマンドを書き込む `validation-report.md` の格納場所）は Step 5 task-plan.md / Step 6 implementer の領域。本ドキュメントでは方針のみ確定する。

## 本質テストケース (TC-NNN)

仕様レベル (intent-spec.md / design.md) で表現可能な振る舞いを検証するケース。Step 4 で qa-analyst が起点を設計、Step 6 で implementer が「振る舞いの追加パターン」を `TC-IMPL-NNN` として継続採番で追記する。

### 削除確認群 (TC-001 〜 TC-004)

| ID     | 対象成功基準 | 期待される振る舞い                                                                       | 実行主体    | 検証スタイル | 判定基準                                                                                                                | 必要理由 (条件付き) | 備考                                              |
| ------ | ------------ | ---------------------------------------------------------------------------------------- | ----------- | ------------ | ----------------------------------------------------------------------------------------------------------------------- | ------------------- | ------------------------------------------------- |
| TC-001 | SC-1         | `specialist-self-reviewer/` ディレクトリが存在しない                                     | `automated` | `existence`  | `test ! -d plugins/dev-workflow/skills/specialist-self-reviewer` の終了コードが `0`                                     | -                   | `git rm -r` で削除                                |
| TC-002 | SC-2         | `agents/self-reviewer.md` が存在しない                                                   | `automated` | `existence`  | `test ! -f plugins/dev-workflow/agents/self-reviewer.md` の終了コードが `0`                                             | -                   | `git rm` で削除                                   |
| TC-003 | SC-3         | `shared-artifacts/templates/self-review-report.md` が存在しない                          | `automated` | `existence`  | `test ! -f plugins/dev-workflow/skills/shared-artifacts/templates/self-review-report.md` の終了コードが `0`             | -                   | `git rm` で削除                                   |
| TC-004 | SC-4         | `shared-artifacts/references/self-review-report.md` が存在しない                         | `automated` | `existence`  | `test ! -f plugins/dev-workflow/skills/shared-artifacts/references/self-review-report.md` の終了コードが `0`            | -                   | `git rm` で削除                                   |

### 残存表記の根絶群 (TC-005 〜 TC-008)

| ID     | 対象成功基準 | 期待される振る舞い                                                                                                       | 実行主体    | 検証スタイル | 判定基準                                                                                                                                                                                                          | 必要理由 (条件付き) | 備考                                                                                          |
| ------ | ------------ | ------------------------------------------------------------------------------------------------------------------------ | ----------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | --------------------------------------------------------------------------------------------- |
| TC-005 | SC-5         | `self[-_]review` または `Self-Review` という表記が `plugins/dev-workflow/` 配下に一切残っていない                        | `automated` | `count`      | `grep -rnE -i 'self[-_]review\|Self-Review' --exclude-dir=.git --exclude-dir=node_modules plugins/dev-workflow/` のヒット件数が `0`                                                                                | -                   | 大文字小文字 / ハイフン / アンダースコア混在を `-i` + `[-_]` でカバー                         |
| TC-006 | SC-6         | `self-reviewer` または `specialist-self-reviewer` の参照が `plugins/dev-workflow/` 配下に一切残っていない                | `automated` | `count`      | `grep -rnE 'self-reviewer\|specialist-self-reviewer' --exclude-dir=.git --exclude-dir=node_modules plugins/dev-workflow/` のヒット件数が `0`                                                                       | -                   | TC-005 とパターンの重複があるが、明示的にエージェント名 / スキル名の参照を別途確認            |
| TC-007 | SC-7         | `Step 10` という表記が `plugins/dev-workflow/` 配下に一切残っていない                                                    | `automated` | `count`      | `grep -rnF 'Step 10' --exclude-dir=.git --exclude-dir=node_modules plugins/dev-workflow/` のヒット件数が `0`                                                                                                       | -                   | 旧 Step 10 = Retrospective が新 Step 9 に繰り上がった結果の検証                               |
| TC-008 | SC-8         | 旧番号でのステップ参照表記 `Step 9 (Validation)` および `Step 10 (Retrospective)` が `plugins/dev-workflow/` 配下に不在 | `automated` | `count`      | `grep -rnE 'Step 9 \(Validation\)\|Step 10 \(Retrospective\)' --exclude-dir=.git --exclude-dir=node_modules plugins/dev-workflow/` のヒット件数が `0`                                                              | -                   | 新番号 `Step 8 (Validation)` / `Step 9 (Retrospective)` のみが残ることを保証                   |

### 構造的完全性群 (TC-009 〜 TC-013)

| ID     | 対象成功基準 | 期待される振る舞い                                                                                                                              | 実行主体    | 検証スタイル | 判定基準                                                                                                                                                                                                                                                                                              | 必要理由 (条件付き) | 備考                                                                                                                                            |
| ------ | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ----------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| TC-009 | SC-9         | `dev-workflow/SKILL.md` のステップ一覧テーブルが 9 ステップで構成され、Step 7 行に `External Review` / `reviewer × N` / `review/<aspect>.md` が並ぶ | `manual`    | `structural` | (1) ステップ一覧テーブルのデータ行数が 9。`grep -nE '^\| Step [1-9] \|' plugins/dev-workflow/skills/dev-workflow/SKILL.md \| wc -l` の結果が 9。(2) Step 7 行の Specialist 列が `reviewer × N (観点並列)` 表記を含み、主要成果物列が `review/<aspect>.md` を含む（目視）。(3) ヘッダ + 区切り行 = 2 行を除いて確認 | -                   | 行数自動カウントは automated だが、セル内容 (Specialist 名 / 並列度 / 成果物名) の意味判定は人間が必要なため `manual × structural` を採用       |
| TC-010 | SC-10        | `dev-workflow/SKILL.md` のロールバック早見表に Step 7/8/9 のエントリが存在し、旧 Self-Review 由来のエントリが External Review に統合されている     | `manual`    | `inspection` | (1) ロールバック早見表セクションを目視。(2) Step 7 (External Review) / Step 8 (Validation) / Step 9 (Retrospective) の 3 エントリが揃う。(3) 旧 「Step 7 (Self-Review)」エントリが残っておらず、その内容（High 指摘 → Step 6 等）が新 Step 7 (External Review) のエントリに `Blocker → Step 6 再活性化` として吸収されている | -                   | エントリ数の自動カウントだけでは「内容の吸収」は判定不能のため `manual × inspection`                                                            |
| TC-011 | SC-11        | `specialist-reviewer/SKILL.md` 本文に「全体整合性」または「整合性」キーワードが複数箇所に存在し、`holistic` 観点が明記されている                | `automated` | `count`      | `grep -cE '全体整合性\|整合性\|holistic' plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の数値が `5` 以上                                                                                                                                                                                | -                   | design.md L411 の検証コマンドに準拠。閾値 5 の根拠は「観点紹介 + 失敗モード + 入出力契約 + 横断ルール + ループ運用」の 5 箇所言及を最低限期待   |
| TC-012 | SC-12        | `shared-artifacts/SKILL.md` の成果物一覧テーブルから `self-review-report.md` 行が削除され、行番号が欠番なしで再付番されている                  | `manual`    | `structural` | (1) 成果物一覧テーブルから `self-review-report.md` 行が削除されている (`grep -nF 'self-review-report' plugins/dev-workflow/skills/shared-artifacts/SKILL.md` が 0 件) — automated 部。(2) テーブルの行番号列（`#` 列がある場合）が `1, 2, ..., N` の連番で欠番なし — 目視部                            | -                   | grep ヒット 0 件は automated だが連番の正当性は人間の目視（行番号列の有無自体が要件外もあり得るため柔軟性確保）                                |
| TC-013 | SC-13        | `shared-artifacts/templates/progress.yaml` から `self_review:` フィールドが削除されている                                                       | `automated` | `count`      | `grep -nE '^\s*self_review:' plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml` のヒット件数が `0`                                                                                                                                                                                | -                   | YAML フィールド削除のみを判定。値や下位構造は対象外                                                                                              |

### メタ整合性群 (TC-014 〜 TC-017)

| ID     | 対象成功基準 | 期待される振る舞い                                                                                              | 実行主体    | 検証スタイル | 判定基準                                                                                                                                                                                                                                                              | 必要理由 (条件付き) | 備考                                                                                                                |
| ------ | ------------ | --------------------------------------------------------------------------------------------------------------- | ----------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------- |
| TC-014 | SC-14        | `README.md` が 9-step 構成と 9 specialist subagents を反映                                                      | `manual`    | `structural` | (1) `grep -nE 'nine specialist\|9-step\|9 specialist' plugins/dev-workflow/README.md` が 1 件以上 — automated 補助。(2) `grep -nE 'ten specialist\|10-step\|10 specialist' plugins/dev-workflow/README.md` が 0 件 — automated 補助。(3) ステップ列挙の本文が 9 ステップで、Self-Review が含まれていない — 目視部 | -                   | 数値 9 の存在 / 数値 10 の不在は automated だが、列挙本文の意味的整合は人間判定                                     |
| TC-015 | SC-15        | `.claude-plugin/plugin.json` の description が 9-step 構成かつ Self-Review 言及なし                            | `automated` | `count`      | (1) `grep -nF 'Self-Review' plugins/dev-workflow/.claude-plugin/plugin.json` のヒット件数が `0`。(2) `grep -nE '9-step\|9 step' plugins/dev-workflow/.claude-plugin/plugin.json` のヒット件数が `1` 以上                                                              | -                   | 2 種類の grep を AND で評価。description は短文のため count のみで判定可能                                          |
| TC-016 | SC-16        | `agents/` 配下に 9 ファイル存在し (`self-reviewer.md` 削除後)、各 description / 本文に Self-Review 言及がない | `automated` | `structural` | (1) `ls plugins/dev-workflow/agents/ \| wc -l` の結果が `9`。(2) `grep -rnE -i 'self[-_]review\|Self-Review' plugins/dev-workflow/agents/` のヒット件数が `0`（TC-005 で全配下を確認済みだが、agents/ サブセットでも独立に検証する）                                  | -                   | TC-005 / SC-5 と重複する観点だが、agents/ 配下のファイル数 + 表記不在の AND 判定として独立 TC を設ける              |
| TC-017 | SC-17        | スキル間クロスリファレンスにリンク切れが発生していない（`specialist-self-reviewer` / `self-review-report.md` 等の旧リンクが現存スキル名 / 現存パスに正しく置換されている） | `manual`    | `inspection` | (1) `grep -rnE 'specialist-[a-z-]+\|review/[a-z-]+\.md\|self-review-report\.md' plugins/dev-workflow/` を実行し、出力をすべて目視。(2) 各参照先のスキル / パスが現存することをファイルシステム上で確認。(3) 旧名の残骸（`specialist-self-reviewer` / `self-review-report.md`）が 0 件であることを再確認                | -                   | 「リンク切れ」は単純な grep では検出不能（参照先の存在確認が必要）。目視リストアップ + ファイル存在確認のハイブリッド作業 |

### 複合検証用テストケース (TC-018, 任意)

下記は Intent Spec の SC-N に直接対応せず、本サイクルの「全 17 SC が 1 コマンドで同時確認できる」確実性を担保する派生 TC。Step 8 Validation の効率化のために設計する。

| ID     | 対象成功基準 | 期待される振る舞い                                                                                              | 実行主体    | 検証スタイル | 判定基準                                                                                                                                                                                                                                                                          | 必要理由 (必須)                                                                                                                                                                                                                                                                              | 備考                                                                                                                |
| ------ | ------------ | --------------------------------------------------------------------------------------------------------------- | ----------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| TC-018 | (なし)       | design.md L438–L494 の検証コマンドセットが 1 セット連続実行で全件 PASS する                                    | `automated` | `count`      | design.md L438–L494 の `bash` コマンドブロック全体を Step 8 validator が 1 セッションで連続実行し、各 grep の期待値（`0` 件 or `1` 件以上）が全て満たされ、`echo "DELETED OK"` が出力されること。失敗があれば `validation-report.md` に該当コマンドと結果を記録                              | リグレッション防止: 個別 TC-001〜TC-017 が個別に PASS しても、validator が手順を逸脱したら検出漏れが発生する。design.md の確定コマンドセットを「1 つのスクリプトとして PASS する」を別途検証することで、Step 8 の手順遂行性を保証する。Markdown サイクルでは唯一の「シナリオ系テスト」相当 | TC-001 〜 TC-016 を 1 度に再検証する性質を持つ。Step 8 Validation の最終ステージで実行することを task-plan で確定する |

### enum 値の早見表

- **実行主体 (`実行主体` 列):** `automated` | `ai-driven` | `manual`
- **検証スタイル (`検証スタイル` 列):** `assertion` | `scenario` | `observation` | `inspection`
- **本サイクルでの拡張運用:** Markdown プラグイン特化のため、`assertion` / `scenario` / `observation` の代わりに静的観測の細分類として `existence` / `count` / `structural` を採用（`shared-artifacts/references/qa-design.md` の業界 taxonomy 表で `automated × assertion` に該当する Markdown 検査の派生表現として位置付ける）
- **禁止組み合わせ:** `automated × inspection` (使用不可) — 本サイクル該当なし
- **要備考組み合わせ (△):** `manual × structural` — 採用時は `備考` 列に「行数 / 連番は機械観測だがセル意味判定は人間が必要」のような構造的観測 + 意味判断の混在理由を記述

`existence` / `count` / `structural` の 3 細分類は本サイクル特有で、`shared-artifacts/references/qa-design.md` の標準 4 enum (`assertion` / `scenario` / `observation` / `inspection`) には属さない。これは「実行可能コードを含まない Markdown サイクル」固有の検証スタイル拡張であり、後続サイクルへの遡及的標準化は qa-analyst スキル本文の Future Work とする。

## 実装都合テストケース (TC-IMPL-NNN)

ライブラリ / フレームワーク / OS など、具体実装でのみ発生する防御的分岐を検証するケース。**Step 4 では空、Step 6 で implementer が発見した場合のみ追記する**。

| ID          | 対象成功基準 | 期待される振る舞い | 実行主体 | 検証スタイル | 判定基準 | 必要理由 (必須) | 備考 |
| ----------- | ------------ | ------------------ | -------- | ------------ | -------- | --------------- | ---- |
| (Step 6 で追記) | -        | -                  | -        | -            | -        | -               | -    |

Step 6 implementer が想定する追記候補（qa-analyst が intent-spec.md の「未解決事項 / 制約」から事前に予測したヒント。実際の追記は implementer の判断）:

- **TC-IMPL 候補 A: 番号繰り上げ後の Markdown 整合性** — 旧 Step 番号と新 Step 番号が混在した文脈（例: `Step 6 ↔ Step 7` の `7` がどちらの番号体系を指すかが曖昧になる）が残っていないか。`gsed` placeholder 戦略で防いでいるが、実装時に発見される複合表現があれば TC-IMPL として追記
- **TC-IMPL 候補 B: frontmatter スキーマ違反検出** — agent / skill description の文字数制約 (250 文字程度) を超える description が新規生成されていないか。`gawk '/^description:/,/^[a-z_]+:/' file.md \| wc -c` 等の機械検出が可能
- **TC-IMPL 候補 C: agent description 文字数制約** — Self-Review 言及削除後に「Do NOT use for」リストが圧縮可能か / 必要かの判断（intent-spec.md L200）。実装時に超過があれば TC-IMPL として追記し、validation で文字数閾値判定
- **TC-IMPL 候補 D: 内部リンクの参照先存在検証** — `[label](path)` 形式の Markdown リンクが指す相対パスが実在するか。`gawk` でリンク抽出 → 各パスを `test -f` する自動化が可能。手動の TC-017 を補完する位置付け

これらは Step 4 時点では予測情報に過ぎないため、本テーブルには記載しない。Step 6 implementer が必要と判断した時点で番号 `TC-IMPL-001` から採番して追記する。

## カバレッジ表

成功基準 → TC-ID の逆引き。Step 8 validator がカバレッジ確認に使用する。本質テスト (TC-NNN) のみが対象。

| 成功基準 ID | 対応する TC-ID | 注記                                                                              |
| ----------- | -------------- | --------------------------------------------------------------------------------- |
| SC-1        | TC-001         | -                                                                                 |
| SC-2        | TC-002         | -                                                                                 |
| SC-3        | TC-003         | -                                                                                 |
| SC-4        | TC-004         | -                                                                                 |
| SC-5        | TC-005, TC-016 | TC-016 が agents/ サブセットを独立に確認、TC-005 が plugins/dev-workflow/ 全体を確認 |
| SC-6        | TC-006         | -                                                                                 |
| SC-7        | TC-007         | -                                                                                 |
| SC-8        | TC-008         | -                                                                                 |
| SC-9        | TC-009         | 行数 9 + セル内容意味判定                                                          |
| SC-10       | TC-010         | 旧 Self-Review 由来エントリの吸収を意味判定                                       |
| SC-11       | TC-011         | grep ヒット件数 5 以上                                                            |
| SC-12       | TC-012         | grep 0 件 + 行番号連番                                                            |
| SC-13       | TC-013         | grep `self_review:` 0 件                                                          |
| SC-14       | TC-014         | grep 数値判定 + ステップ列挙の意味判定                                            |
| SC-15       | TC-015         | grep 2 種類の AND 判定                                                            |
| SC-16       | TC-016         | ファイル数 9 + Self-Review 表記 0 件 (TC-005 と二重カバレッジ)                    |
| SC-17       | TC-017         | クロスリファレンスのリンク切れ非発生（手動目視）                                  |

**カバレッジ確認結果**: 全 17 成功基準が少なくとも 1 つの本質テスト (TC-001〜TC-018) でカバーされている。SC-5 と SC-16 は意図的に二重カバレッジ（agents/ サブセットの独立検証）。Step 1 ロールバック判断は不要。

### 検証主体の分布

- **automated**: TC-001 〜 TC-008、TC-011、TC-013、TC-015、TC-016、TC-018 の **13 件**（76%）
- **manual**: TC-009、TC-010、TC-012、TC-014、TC-017 の **5 件**（24%、うち `manual × inspection` が 2 件、`manual × structural` が 3 件）

`manual` の比率が 24% に抑えられているのは、Markdown サイクルでありながら Intent Spec の成功基準が `grep` / `test` / `wc -l` で観測可能な形で記述されているため。残り 5 件の `manual` は **意味的整合性**（旧知見の吸収 / リンク切れの参照先存在 / セル内容の意味判定）で、機械検出不能のため不可避。
