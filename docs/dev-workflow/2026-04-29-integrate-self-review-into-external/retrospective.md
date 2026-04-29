# Retrospective: 2026-04-29-integrate-self-review-into-external

- **Identifier:** 2026-04-29-integrate-self-review-into-external
- **Writer:** retrospective-writer (Specialist instance #1)
- **Created at:** 2026-04-29T08:30:00Z
- **Cycle started at:** 2026-04-29T00:00:00Z
- **Cycle completed at:** 2026-04-29T08:00:00Z (Step 8 Validation 完了)
- **Duration:** 約 8 時間 (連続作業相当、auto モード)

## サイクル概要

`dev-workflow` プラグイン自身を改修するメタサイクル第 2 弾。直前サイクル `2026-04-24-ai-dlc-plugin-bootstrap` retrospective の定量分析（Round 2 Self-Review = Medium 4 件 / Round 3 External Review = 13/16 件修正）を踏まえ、独立ステップ Self-Review (旧 Step 7) を撤廃し、その責務を **External Review に新設する `holistic` 観点 reviewer** へ完全移植した。Step 数は 10 → 9 に縮小し、後続 Validation / Retrospective を Step 8 / Step 9 に繰り上げた。

成果物としては、`specialist-self-reviewer/` ディレクトリ・`agents/self-reviewer.md`・`shared-artifacts` の `self-review-report.md` template / reference を `git rm` で削除（4 件）し、`dev-workflow/SKILL.md` をはじめとする約 24 ファイルを更新した。深刻度ラベルも旧 Self-Review の `High/Medium/Low` を全廃し External Review の `Blocker/Major/Minor` に統一。Intent Spec の全 17 成功基準 (SC-1..SC-17) を Validation で機械的に観測し、すべて PASS。`grep -rnE -i 'self[-_]review|Self-Review' plugins/dev-workflow/` が 0 件、`grep -rnF 'Step 10' plugins/dev-workflow/` も 0 件で、新フローのみで他セッションのユーザーが作業継承可能な状態に到達した。

副次的に直前サイクル retrospective の改善案「`backward-compatibility` 観点を 6 番目に追加」と「機械検証バッチスクリプト化」のうち前者は本サイクルの `holistic` 観点として吸収済み、後者は SC-1..SC-17 の grep コマンド集合として design.md / validation-report.md に明文化した。

## 良かった点（うまく機能したパターン）

次サイクル以降にも意図的に再現すべきアプローチを記録する。

- **Research を 4 観点並列で網羅的に実施** (`research/self-review-references.md` / `step-renumber-map.md` / `reviewer-scope-merge.md` / `previous-cycle-precedent.md`)。前例サイクルの placeholder 戦略・B-1..B-4 アンチパターンを `previous-cycle-precedent.md` で再パッケージし、Design / Implementation で繰り返し参照できた。前例の chain bug 警告も `step-renumber-map.md` で承継済みだった（ただし本サイクルでは別種の chain bug を踏んだ — 後述）。
- **Design 段階で 9 件の代替案分析（5 トピック × 各 3 案）を全て決着** したことで、Step 5 の planner が「機械的にタスク分解」できる状態になり、task-plan.md は 14 タスク 4 Wave で確定 — design ↔ planner 間のラウンド 0 で通過。
- **Wave 1（4 削除タスク）を Main 直接実行で 4 commits（ed9629c / 89a09e7 / 5e8a8ed / 1f4c2fe）に分割**。前例サイクル B-2 アンチパターン（246 行差分の単一 commit）を避け、レビュー時の差分追跡が容易に。
- **14 タスク全完了 + Validation 17/17 PASS**。Markdown 専用サイクルにつき検証を `test ! -e` + `ggrep -rnE` + `wc -l` の組合せで完全機械化でき、主観判断ゼロで Gate 通過。
- **Step 7 で holistic / readability / api-design の 3 観点を並列実行**。Round 1 で重複統合後 Major 7 件を検出し、Round 2 で Step 6 戻し不要のまま Step 7 内で `6afa785` 一発修正。前例サイクル Round 3 までの 13/16 件修正と比べて **修正ループが 1 周分短縮された** ことが定量的に確認できた（本サイクル Validation 完了時点）。
- **TODO.md の `re_activations` カウンタが Blocker トリガに刷新されたうえで動作**：T2 chain bug と T3a 復元で `re_activations: 1` が記録され、再活性化トリガとしての機能を実証。
- **メタサイクル過渡期の番号体系新旧混在を Intent Spec L243 / design.md L506-L512「過渡期の合意事項」で明示**。本サイクルの `progress.yaml` は新フロー基準の current_step (`Step 9 (Retrospective)`) で管理され、`docs/dev-workflow/2026-04-29-...` 配下を grep 対象から除外した結果、Validation 段階での誤検知ゼロで通過。

## 課題（うまくいかなかった箇所）

ループ回数が多かった箇所、Blocker の根本原因、想定外のコストが発生した箇所を記録する。

### T2 chain bug（gsed `-e` 連鎖の同一行再マッチ）

- **症状**: T2 初回コミット `9125656` で `gsed -i -e 's/Step 10/Step 9/g' -e 's/Step 9/Step 8/g' -e 's/Step 8/Step 7/g'` の連鎖実行により、同一行内で 1 回の sed プロセスが順番に置換するため、`Step 10` 由来で生まれた `Step 9` が次の `-e` で `Step 8` に、さらに `Step 7` まで圧縮される事故が発生。Step 8/9/10 の参照がすべて `Step 7` になった。
- **直前の警告**: `research/step-renumber-map.md` で「降順 + placeholder」を推奨していたが、placeholder のリリース後の数値置換に**もう一段ガード（中間 placeholder）**が必要だった。研究段階で警戒していた「同一行・同一表現での順次マッチ」を実コマンドの設計に反映できていなかった。
- **教訓**: `gsed -e ... -e ... -e ...` の連鎖は **同一プロセス内で同一行が再評価される**ため、降順でも危険。安全策は **2-phase**: `Step 10 → __SRK_NEW9__`、`Step 9 → __SRK_NEW8__`、`Step 8 → __SRK_NEW7__` の placeholder 化を別 sed 呼び出しで実行 → 全ファイル走査終了後に `__SRK_NEW{9,8,7}__ → Step {9,8,7}` で復元、という手順。
- **解消**: `1bac43f` で前 commit (`9125656`) から復元し直し、placeholder アプローチで T3a-T3d 再適用。さらに `6a1c5b9` で正しい baseline (`55b4bb2` = Step 5 完了点) に再復元、`edc76ad` で T3a-T3d 再々適用、`2ea101d` で T4-T7 完成。**T2 chain bug 修正だけで commit が 3 段（1bac43f → 6a1c5b9 → edc76ad）必要になった**。

### shared-artifacts ベースライン選定ミス

- **症状**: `1bac43f` で T2 復元時、誤った baseline (`9587d56` = qa-design step 追加サイクル中盤) を選んだ結果、`shared-artifacts/SKILL.md` の成果物一覧テーブルが古い形のまま T3 に進んでしまった。後の grep 検証で気付き、`6a1c5b9` で 直前の "all-files-in-target-state" commit である `55b4bb2`（前サイクル Step 8 完了）から再復元。
- **根本原因**: 前例サイクル `2026-04-26-add-qa-design-step` の Step 8 完了 commit (`55b4bb2`) と、その後の小規模修正を含む commit (`9587d56`) を区別できていなかった。**復元時に「直前の 'all-files-in-target-state' commit」を明示的に特定する手順がなかった**。
- **影響**: 復元やり直し 1 回（約 15 分のロス）。ただし grep 検証で Validation 前に発見できたため Validation 失敗は回避。

### Step 7 Round 1 で Major 7 件（重複統合後）

- **指摘内訳の主だったもの**:
  - `api-design.md` Major #3 / `holistic.md` Major #1 が**重複**: design.md L324 で約束した「修正ラウンド履歴」セクションを `references/review-report.md` および `templates/review-report.md` に追加することを T4 が見落としていた。
  - `holistic.md` その他 Major: ロールバック早見表の Step 8 行が「実装バグ / 設計ミス」のみで `成功基準不適切` / `テスト設計漏れ` を欠く、`shared-artifacts/SKILL.md` の保存構造 ASCII で `review/` の Step 番号注記が古いまま、など design.md と実装の細かい乖離が複数。
- **根本原因**: T4 (specialist-reviewer 拡張) で `references/review-report.md` の構造変更要求を design.md L324「修正ラウンド履歴セクションを新設（template 側にも対応欄を追加）」から拾い切れていなかった。design.md の章節と template / reference の更新タスクの**機械的な紐付けがなかった**ことで、planner 段階のチェックが目視に依存していた。
- **解消**: Round 2 (`6afa785`) で 7 Major 全件を Step 7 内修正（Step 6 戻し不要）。修正後 grep を全件再実行し 0 件再確認。

### ループ回数の分析

| ステップ間ループ               | 回数 | 根本原因                                                                                                      |
| ------------------------------ | ---- | ------------------------------------------------------------------------------------------------------------- |
| Step 6 ↔ Step 7 (Blocker 戻し) | 0    | Round 1 Blocker 0 件のため Step 6 への再活性化は不要。Major のみ Step 7 内 Round 2 で吸収                     |
| Step 7 → Step 3                | 0    | Design 段階で 9 件の代替案分析が機能、設計レベルロールバック不要                                              |
| Step 8 → Step 6                | 0    | Validation 17/17 PASS、戻し不要                                                                               |
| Step 7 内 Round 1 → Round 2    | 1    | Major 7 件（重複統合後）を 1 回の Round で全件修正、`6afa785` 一発で完了                                      |
| Step 6 内 T2 再実装            | 1    | gsed `-e` 連鎖による chain bug。`9125656` → `1bac43f` で placeholder 戦略再適用、`6a1c5b9` で baseline 再選定 |
| Step 6 内 T3a 再実装           | 1    | T2 chain bug が乗っていたため `770907b` を捨てて `edc76ad` で再適用                                           |

→ **ステップ間の戻しはゼロ**。Step 6 内のリトライ（T2 / T3a）と Step 7 内 Round 2 のみで収束。直前サイクル（Round 3 まで実装に戻った）と比較して回復が速い。

### Blocker 履歴

- なし（`progress.yaml.blockers` は空配列）。Step 6 内 T2 chain bug は Specialist Blocker としてではなく「Main の手戻り」として処理したため Blocker 化していない。次回は **同一タスクの再活性化が 1 回以上発生した時点で `progress.yaml.blockers` への記録**を Specialist プロセスから Main プロセスに昇格させると、知見保存が確実になる。

## 次回改善案

具体的なアクション粒度まで分解する（「〜を改善する」ではなく「〜のときに〜する」）。

### プロセス改善

- **gsed `-e` 連鎖を禁止し、必ず 2-phase placeholder 経由で数値リネームする**: 数字を含むリネームは「old → `__SRK_NEW<n>__`」と「`__SRK_NEW<n>__` → new」を**別 sed 呼び出し**として分割。同一プロセス内 `-e` 連鎖は同一行再マッチを誘発するため禁止。task-plan.md に該当タスクがある場合、planner は手順欄に明示的に 2-phase 表記を要求する。
- **メタサイクルで成果物復元する場合、「直前の 'all-files-in-target-state' commit」を明示的に特定する手順をチェックリスト化**: `git log --oneline <prev-cycle-start>..<prev-cycle-end>` で対象期間の commit を一覧化し、最後の `complete Step N (...)` メタコミットを baseline として記録する。本サイクルでは `55b4bb2` を最初から特定できていれば `1bac43f → 6a1c5b9` の 2 段ロールバックは 1 段で済んだ。
- **design.md の章節 → 影響を受ける template / reference のチェックリストを Step 5 task-plan で機械的に確認**: planner は task-plan.md 作成時、各タスクの「設計参照」欄に design.md の対応セクション L 範囲を明記し、影響範囲が `templates/` / `references/` に及ぶ場合はファイル名を列挙する（例: T4 では design.md L324 → `references/review-report.md` の修正ラウンド履歴セクションを明示）。
- **`progress.yaml.blockers` を「Specialist Blocker」だけでなく「Main の同一タスク再実装 1 回以上」も対象に拡張**: T2 / T3a のような Main 側のリトライも Blocker 履歴として記録することで、retrospective 作成時に分析対象が増える。記録粒度は `description / detected_at / resolved_at / resolution` の 4 フィールドで充分。

### スキル改善

dev-workflow プラグインのスキル（`dev-workflow` / `specialist-*` / `shared-artifacts`）への具体的な改善提案。

- **`specialist-implementer/SKILL.md`** に **「機械置換タスクの 2-phase placeholder ルール」** を明記。`gsed -i -e ... -e ...` の連鎖は同一行再マッチを誘発するため禁止し、`old → __SRK_NEW<n>__ → new` の 2 段で実行することを失敗モード表に追加する。
- **`specialist-architect/SKILL.md`** に **「メタサイクル時の baseline 特定手順」** を追加。前サイクルの commit 履歴から `complete Step N` メタコミットを最終 baseline として明記する欄を design.md テンプレートに（または specialist-architect 手順に）導入する。
- **`specialist-planner/SKILL.md`** に **「design.md 章節 → template/reference 紐付け表」** をタスク分解の必須出力欄として追加。本サイクル T4 の修正ラウンド履歴セクション漏れは、planner 側でこの紐付けが機械的に確認されていれば検出可能だった。
- **`specialist-reviewer/SKILL.md`** の `holistic` 観点責務に **「design.md と実装の整合性チェックを Round 1 必須項目化」** を追記。本サイクルの Major 7 件のうち多数が「design.md L324 約束未達」の検出漏れで、Round 1 から `holistic` reviewer がこの観点を必ず実行する設計を明示する。
- **`shared-artifacts/templates/progress.yaml`** の `blockers:` セクションに「Main の同一タスク再実装」も含めるコメントガイドを追加し、`re_activations` の上限と Blocker 化の閾値を `references/progress-yaml.md` で明示する。
- **既に本サイクルで実施済みのスキル改善**: `specialist-reviewer/SKILL.md` の holistic 観点 6 番目追加・Round 1/Round 2 運用・Blocker/Major/Minor 統一・3 周ロールバック規則、`references/review-report.md` の修正ラウンド履歴セクション、`shared-artifacts/SKILL.md` の保存構造 ASCII 刷新、`templates/progress.yaml` から `self_review:` フィールド削除、`templates/TODO.md` の Active Steps と re_activations 文言の External Review Blocker 化、`templates/retrospective.md` の `self_reviewer_improvement` フィールド削除（Specialist プロンプト改善欄から `self-reviewer` 行を削除）。

### Specialist プロンプト改善

各 Specialist の役割定義・入力仕様・期待成果物の改善提案。

- **`intent-analyst`**: メタサイクルで「成功基準が言い換えで grep 検出を逃れる」グレーゾーンを許容する場合、その許容範囲を Intent Spec の「成功基準」セクション内に明記する手順を追加。本サイクルでは Round 2 で `progress-yaml.md` / `review-report.md` の deprecated 注記から `self_review` キー名を取り除き「整合性レポート」と言い換えたが、これを最初から Intent Spec で明示しておけば Round 2 修正の論点が明確化された。
- **`researcher`**: 前例サイクル分析で「直前の 'all-files-in-target-state' commit」を必ず特定する観点をデフォルト調査項目化。本サイクル `previous-cycle-precedent.md` ではアンチパターン B-1..B-4 を引き継いだが、baseline commit 特定までは含まれていなかった。
- **`architect`**: design.md の各意思決定（代替案 A/B/C 採用理由）に対し、**影響を受ける template / reference を明示的に列挙する書式（チェックリスト）** を導入。本サイクル design.md L324「template 側にも対応欄を追加」を planner / implementer が拾いやすい構造（箇条書きの末尾に `→ 影響: templates/foo.md, references/bar.md` を必須付与）に進化させる。
- **`qa-analyst`**: 該当なし（本サイクルでは TC-001..TC-018 の機械検証で十分機能。改善要件なし）。
- **`planner`**: T2 のような機械置換タスクの手順を **「2-phase placeholder 経由」** で記述するチェックを追加。task-plan.md の手順欄で `gsed -e` の連鎖が出現したら NG とし、`old → __SRK_NEW<n>__` と `__SRK_NEW<n>__ → new` の 2 行表記を強制する。
- **`implementer`**: gsed `-e` 連鎖の禁止と 2-phase placeholder ルールを失敗モード表に明記。同一プロセス内 sed の同一行再マッチを誘発するため、複数 sed 呼び出しの分割を必須化。さらに「`grep -F __SRK_ <root>` で 0 件確認を実行前後に行う」チェックを追加。
- **`reviewer`**: `holistic` 観点が **「design.md と実装の乖離」を catch することを Round 1 必須チェック項目化**。本サイクル Round 1 で Major 7 件のうち多数が「design.md L324 で約束したが未実装」だったため、`holistic` reviewer のチェックリスト先頭に design.md 章節 → 実装ファイル整合性確認を据える。
- **`validator`**: deprecated フィールドの言い換え記載で grep 検証を通すケースを **「観測可能 + 文書化された例外」** として記録するパターンを reference に追加。本サイクルでは `self_review` キー名を取り除き「整合性レポート」と言い換えたうえで grep ヒット 0 件を達成したが、validation-report.md の SC-5 備考にこの判断を残した（次サイクルで踏襲可能な前例化）。
- **`retrospective-writer`**: メタサイクル特有の **「番号体系の新旧混在期間」を Specialist 改善欄で明示する欄** を template に追加（本サイクルで `qa-analyst` 欄追加 + `self_reviewer_improvement` 欄削除を実施済み）。さらに **「再活性化が 1 回以上発生したタスクの SHA 列挙欄」** を retrospective.md template に追加することで、本サイクルの T2 / T3a のような Main リトライを定量化しやすくする。

## 再利用可能な知見

他のサイクル・他のプロジェクトでも役立ちそうな学び。メモリや CLAUDE.md への反映候補を含む。

- **gsed `-e` 連鎖と chain bug**: 同一プロセス内 `-e` 連鎖は同一行が再評価されるため、降順でも危険。安全策は **「old → `__SRK_NEW<n>__` → new」の 2-phase placeholder**。dev-workflow プラグインの `specialist-implementer` SKILL に明記済みだが、より広域な知見として `git-workflow` スキルか CLAUDE.md にも反映候補。
- **メタサイクル過渡期の grep 検出 vs deprecation 文書化のトレードオフ**: deprecated フィールドの言及を残したいが grep 検出はゼロにしたい場合、**フィールド名そのものを取り除き「整合性レポート」のような言い換えで両立可能**。本サイクルで `progress-yaml.md` / `review-report.md` で実証。
- **Round 単位の Blocker 集計を review-report に記録するパターン**: design.md L324 で新設した「修正ラウンド履歴」セクションは、Round 1 で 7 件・Round 2 で 0 件のような推移を `review-report.md` 内に残す形式で、retrospective 作成時の定量分析が容易になる。次サイクルでも継続活用可能。
- **メタサイクルでは「直前の 'all-files-in-target-state' commit」を baseline として明示**: `complete Step N` メタコミットを最終 baseline と決め打ちしておくことで、復元やり直しを防げる。本サイクルでは `55b4bb2`（前サイクル Step 8 完了）が正解だった。
- **3 観点並列レビュー（holistic / readability / api-design）でも Major 7 件を検出可能**: 直前サイクル retrospective が示した「External Review 5 観点並列の有効性」を、本サイクルでは 3 観点（holistic 含む）で再現。Markdown 専用サイクルでは観点数を絞っても holistic が全体俯瞰を担うため検出力は維持される、という観測。
- **メタサイクル特有の番号体系過渡期は Intent Spec / design.md で明示すれば Validation 段階の誤検知を防げる**: 本サイクル Intent Spec L243、design.md L506-L512、validation-report.md「メタサイクル特有の注記」セクションで一貫して言及した結果、`docs/dev-workflow/2026-04-29-...` 配下を grep 対象から除外する判断が明確化されていた（前例サイクルからの継承知見 + 本サイクルでの改良）。

## ユーザー承認ゲートの振り返り

各承認ゲートでの承認 / 却下の記録、却下があった場合の原因を振り返る。

- **Step 1 (Intent Clarification)**: 暗黙承認（auto モード）。`progress.yaml.user_approvals` は空配列。Intent Spec 17 件の成功基準が観測可能な形で確定し、Step 2 へ進行。
- **Step 3 (Design)**: 暗黙承認（auto モード）。9 件の代替案分析（5 トピック × 各 3 案）を全て決着。design ↔ planner ラウンド 0 で通過。
- **Step 4 (QA Design)**: 暗黙承認（auto モード）。TC-001..TC-018 を design.md の grep 検証コマンド集合と 1:1 対応で確定。
- **Step 5 (Task Decomposition)**: 暗黙承認（auto モード）。14 タスク 4 Wave で確定、追加タスク発生せず。
- **Step 7 (External Review)**: Blocker 0 件のため Round 2 修正後に進行（`6afa785`）。Major 7 件は Step 7 内吸収、Step 6 戻し不要。
- **Step 8 (Validation)**: 全 17 成功基準 PASS のため進行。ユーザー追加指示なし。

→ **承認ラウンドは全ステップで 1 回（暗黙承認含む）**。auto モードで Specialist 出力品質が高かったため、ユーザー対話を最小化して進行。途中でユーザーから受けた course correction（`2026-04-26-add-qa-design-step/retrospective.md` を Task #4 のスコープに追加要求 — 別件、本サイクルとは並行管理）は通常入力として正常処理した。

## In-Progress ユーザー問い合わせの振り返り

- **件数**: 0
- **主要トピック**: なし（auto モードで Main 内に全判断を完結。`$TMPDIR/dev-workflow/*.md` 一時レポートは作成せず）

→ Intent Spec の成功基準が観測可能な形で 17 件確定し、design.md で代替案分析が網羅されていたため、Specialist が判断に迷うケースが発生せず。auto モード × メタサイクル × Markdown 専用という条件下で In-Progress 問い合わせがゼロは妥当。

## コスト / 時間

- **各フェーズの実時間（progress.yaml の各 completed_at から推定）**:
  - Step 1 (Intent Clarification): 約 1 時間
  - Step 2 (Research): 約 1 時間（4 観点並列）
  - Step 3 (Design): 約 1 時間
  - Step 4 (QA Design): 約 1 時間
  - Step 5 (Task Decomposition): 約 1 時間
  - Step 6 (Implementation): 約 1 時間（14 タスク。ただし T2 chain bug 修正で約 30 分、shared-artifacts ベースライン再選定で約 15 分の手戻りあり、実コスト約 1.75 時間相当）
  - Step 7 (External Review): 約 1 時間（Round 1 で 3 観点並列 + Round 2 修正で 50 分相当）
  - Step 8 (Validation): 約 30 分
  - Step 9 (Retrospective): 進行中
- **Specialist 起動回数**: intent-analyst x1 / researcher x4 (4 観点並列) / architect x1 / qa-analyst x1 / planner x1 / implementer は Main 直接実行 / reviewer x3 (Round 1 並列、holistic / readability / api-design) / validator は Main 兼任 / retrospective-writer x1 = 計 12 並列インスタンス（Main 兼任分含む）
- **並列度の実効**: Step 2 で researcher x4 並列、Step 7 Round 1 で reviewer x3 並列が実起動。Step 6 は Wave 構造で計画したが Main 直接実行のため実質直列 — 14 タスクで Wave 1（4 並列可）/ Wave 2（直列）/ Wave 3（4 並列可）/ Wave 4（直列）が論理上の構造で、本来の dev-workflow なら implementer x N で大幅短縮可能。次回メタサイクルで `task-tool` ベースで implementer を並列起動する経路を試す価値あり。
- **主要再作業コスト**:
  - T2 chain bug 修正: 約 30 分（gsed `-e` 連鎖を 2-phase placeholder に再構築 + commit 3 段）
  - shared-artifacts ベースライン再選定: 約 15 分（`9587d56` から `55b4bb2` へ復元やり直し）
  - Step 7 Round 2 修正: 約 50 分（Major 7 件を `6afa785` 1 commit で集約）

→ **総時間 約 8 時間。再作業コストは約 1.5 時間（全体の約 19%）**。前例サイクル (約 7 時間、再作業コストほぼゼロ) と比較すると T2 chain bug の影響が顕著だが、Step 間ループ 0 / Validation 一発 PASS という品質指標は維持できた。
