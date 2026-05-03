# Retrospective: 2026-04-29-add-dev-roadmap-skill

- **Identifier:** 2026-04-29-add-dev-roadmap-skill
- **Writer:** retrospective-writer (single instance, Step 9)
- **Created at:** 2026-05-01T11:00:00Z
- **Cycle started at:** 2026-04-29T00:00:00Z
- **Cycle completed at:** 2026-05-01T10:00:00Z
- **Duration:** 約 58 時間 (うち離席中の auto モード約 11 時間で Step 1 改訂以降を完走)

## サイクル概要

`dev-workflow` (1 サイクル = 1 機能 / 1 PR 規模) の上位層として `dev-roadmap` スキルを新設し、複数サイクルを束ねる戦略層の概念を導入したサイクル。新規 1 Main スキル + 3 Specialist スキル + 3 Agent + 4 テンプレート/リファレンスペアを追加し、既存 `dev-workflow/SKILL.md` / `specialist-common/SKILL.md` / `shared-artifacts/SKILL.md` / `progress.yaml` テンプレートに後方互換な追記を行った。

進行中に origin/main マージで 4 つの前提崩壊 (9 ステップ体系移行 / `docs/dev-workflow` → `docs/workflow` リネーム前提 / retrospective 集約形式移行 / SC-12 ベースライン再定義) が発生し、Step 4 進行中に Plan D (ピンポイント差し戻し) で Step 1 → 3 → 4 を順次更新する形式でリカバリ。後段で Step 7 reviewer 4 観点が path 残存問題を早期検出し、T13-T15 の後発タスク 3 件を追加して Step 8 全 14 SC PASS を達成した。本サイクル自体は roadmap 配下ではない独立サイクル (`progress.yaml.roadmap == null`) で、新方式の自己適用は次サイクル以降に委ねる。

## 良かった点

- **ユーザー指示「最後まで進めて」に対し離席中の auto モードで完走できた**: ユーザー対話を要する初期 2 ゲート (Step 1 initial / Step 3 initial) は対話で確定し、その後の Step 1 改訂 / Step 3 改訂 / Step 4 / Step 5 / Step 8 の 5 ゲートを auto 承認で連続消化。Plan D ロールバックを挟みながら 1 セッション内で Step 9 まで到達した。
- **Plan D (ピンポイント差し戻し) が前提崩壊リカバリに有効**: 4 つの前提崩壊に対し、案 A (全面 soft rollback) でも案 C (Main 直接編集) でもなく、Step 1 / Step 3 / Step 4 を順次新規 Specialist で機械的に更新する Plan D を採用。「Specialist が成果物を作る」原則を守りつつ、対話ループ巻き戻しを回避できた (一時レポート `step4-main-merge-impact.md` 参照)。
- **Step 7 reviewer 4 観点が path 残存問題を早期検出**: `consistency` / `backward-compatibility` / `holistic` 3 観点が独立に「task-plan の path 置換対象が 3 ファイルに過小、29 ファイルに `docs/dev-workflow/` が 33 箇所残存」を検出し、ユーザー判断ポイントを構造的に提示。Plan D が拾えなかったスコープ漏れを reviewer がカバーする形でセーフティネットが機能した。
- **T13-T15 後発追加で Step 7 → Step 6 ロールバックを最小化**: 機械的修正 (sed 一括置換 / 旧ステップ番号修正 / サイクル固有参照削除等) の場合は Step 7 再実行をスキップし、Step 8 Validation で実測する判断を採用。3 commits (37eb0d3 / aa14c1e / 551e497) で Major 全件解消。
- **design 確定 5 のシンプル化 (events 構造廃止)**: 当初案にあった `events[]` 配列構造を破棄し、最小スキーマ (`milestones[].status` + `workflow_identifiers[]` + `roadmap.id` ← → `progress.yaml.roadmap` の双方向参照) + git 3-way merge 任せの方針へ簡素化。ユーザー意図 (「最小スキーマで十分」) と整合。
- **T7 implementer の 8 ファイル一括作成が統一スタイルで完遂**: roadmap 系 templates 4 + references 4 を 1 commit (fca9a23) で生成。frontmatter / セクション構造 / プレースホルダ命名規則がファイル間で揃い、Step 7 documentation-quality reviewer から「構造的整合性は高い」と評価された。
- **`progress.yaml.roadmap` ネスト構造採用**: 当初フラット 2 フィールド (`roadmap_id` / `milestone_id`) 案だったが、ユーザー指示でネスト構造 (`roadmap.id` / `roadmap.milestone.id`) に変更。`roadmap == null` で `milestone` 単独存在の矛盾を構造的に排除し、将来拡張余地も確保した。
- **`docs/retrospective/` 集約 + `roadmap-` prefix 命名**: dev-workflow 側の retrospective 集約方針 (`2026-04-29-retro-cleanup` で確立) と整合させ、roadmap 側は `docs/retrospective/roadmap-<roadmap-id>.md` で命名衝突を回避。Open Questions #1 として認識して Step 3 Design で確定 (案 D)。

## 課題

### ループ回数の分析

| ステップ間ループ                         | 回数 | 根本原因                                                                                                                                                                    |
| ---------------------------------------- | ---- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Step 4 → Step 1 (Plan D ロールバック)    | 1    | main マージで 4 前提崩壊 (9 ステップ移行 / docs path rename / retrospective 集約 / SC-12 baseline)。サイクル進行中に companion ブランチ 2 件が main にマージされた          |
| Step 7 → Step 6 (Major 戻し)             | 1    | task-plan の path 置換対象スコープ過小 (3 ファイル指定 → 32 箇所取りこぼし) と sub-Specialist の旧ステップ番号混入。Step 6 再実装は機械的修正のため Step 7 再実行はスキップ |
| Step 6 ↔ Step 7 (Blocker 戻し)           | 0    | Step 7 Round 1 で Major 3 件 (path 残存 / TC-029-030 観測手段 / SC-12 観測手段) 検出。Blocker は 0 件                                                                       |
| Step 8 → Step 6 / Step 4                 | 0    | Step 8 Validation で 14 SC 全件 PASS (TC-015 はテンプレート Mustache 由来の擬似 fail、置換後 parseable で代替確認済)                                                        |
| 同一タスク再活性化 (re_activations >= 1) | 0    | T0-T15 全 16 タスクすべて Round 1 で完了、再活性化発生なし                                                                                                                  |

**T13-T15 タスクの後発追加コミット**: 37eb0d3 (T13: path 一括置換 32 箇所 / 29 ファイル)、aa14c1e (T14: 旧 10 ステップ番号修正 Step 8/9/10 → Step 7/8/9)、551e497 (T15: dev-workflow/SKILL.md 番号付け修正 + サイクル固有参照削除 + README 英日混在修正)。

### Blocker 履歴

`progress.yaml.blockers` は終端時点で空配列。本サイクル中の重大事象は以下のロールバック 2 件にすべて吸収された:

- **2026-04-29T07:00:00Z (Step 4 → Step 1)**: main マージによる 4 前提崩壊。Plan D で Step 1 → 3 → 4 を順次新規 Specialist インスタンスで機械的更新。一時レポート `/tmp/claude-501/dev-workflow/step4-main-merge-impact.md` でユーザー判断 (案 D 採用) を確定後にリカバリ実行
- **2026-05-01T08:30:00Z (Step 7 → Step 6)**: Step 7 reviewer 4 観点が Major 3 件検出 (path 置換スコープ過小 / TC-029-030 観測手段 / SC-12 観測手段)。Step 6 を再活性化して T13-T15 を後発追加、Step 7 再実行はスキップ (機械的修正のため)

### 課題 1: task-plan の path 置換対象スコープが Intent Spec と乖離

- **観測**: Intent Spec L23「path 表記は全てリネーム後の新パスを前提とする」に対し、design.md「既存スキルへの最小変更影響表」(L313-330) と task-plan.md (T8 / T9 / T10) は path 置換対象を `dev-workflow/SKILL.md` / `specialist-common/SKILL.md` / `shared-artifacts/SKILL.md` の 3 ファイルに限定。結果、`agents/*.md` 7 件 / 他 `specialist-*/SKILL.md` 8 件 / `shared-artifacts/{references,templates}/` 14 件の計 29 ファイル / 32 箇所で旧 `docs/dev-workflow/` 表記が残存
- **発見ステップ**: Step 7 (3 reviewer が独立に同一指摘 — `consistency` Major-2、`backward-compatibility` Major-1、`holistic` Major-1)
- **根本原因**: design.md / task-plan.md 作成時に `ggrep -rln "docs/dev-workflow/" plugins/dev-workflow/` 等の網羅的検索を行わず、目視で「主要 3 ファイル」だけ列挙したこと。task-plan.md L252 R1 緩和策には「Step 8 Validation で `ggrep -rn "docs/dev-workflow" plugins/dev-workflow/` 0 件」が書かれていたが、これは事後検査のみで「事前のタスク列挙が網羅的か」を検証していない
- **解消経路**: T13 (commit 37eb0d3) で `ggrep` ベースの一括 `gsed` 置換を実施 (32 箇所 / 29 ファイル)、Step 8 Validation `ggrep -rn` で 0 件確認

### 課題 2: TC 観測手段の不整合 (Major-2 / Major-3)

- **観測**: holistic reviewer が指摘した 2 件 — (a) TC-029 / TC-030 が `ggrep` 行内マッチを要求するが、specialist-common/SKILL.md frontmatter の Specialist 列挙は YAML 多行形式で改行を含むため fail、(b) TC-017 / TC-026 / TC-028 が `git diff --find-renames <baseline>..HEAD -- docs/workflow/<cycle>/` 単一パス指定で rename detection を機能させられず誤陽性 (`+1893 insertions` 等)
- **発見ステップ**: Step 7 (`holistic` Major-2 / Major-3)
- **根本原因**: qa-design.md 作成時に grep ベース TC を実際の対象ファイル状態 (frontmatter 多行 description の構造、git rename detection の pathspec 要件) で動作確認せず、想定で書いた。前提崩壊リカバリで qa-design を再実行した際も再検証されなかった
- **解消経路**: Step 8 Validator が代替手段で実測 — TC-029 は `gawk \| gtr ',' '\n' \| ggrep -oE ... \| gsort -u \| gwc -l = 12` のカウント方式に変更、TC-028 は `--find-renames -M50% docs/workflow/<cycle>/ docs/dev-workflow/<cycle>/` で双方 pathspec 指定。qa-design.md 自体は immutable 原則で修正せず、`validation-report.md` のインライン記録で観測手段を補正 (Round 2 で補助ディレクトリ `validation-evidence/` は廃止し、検証ログを直接 validation-report に埋め込み)

### 課題 3: 旧 10 ステップ番号 (Step 8 / 9 / 10) が `specialist-roadmap-retrospective-writer/SKILL.md` に混入

- **観測**: T4 (commit 011daa3) で新設した SKILL のスコープ外セクション L135 に「Step 8 External Review / Step 9 Validation / Step 10 Retrospective」が残存
- **発見ステップ**: Step 7 (`consistency` Major-1 / `documentation-quality` Major-1)
- **根本原因**: T4 implementer がテンプレート参照 (おそらく古い design 草稿または既存 specialist-retrospective-writer 本文の旧表記) をそのままコピーし、9 ステップ体系への置換を実施しなかった。design.md L518-522 で「ステップ番号置換済」と明記されていたが、design 改訂は post-rollback で行われており、置換完遂までの伝播を T4 タスク仕様で明示していなかった
- **解消経路**: T14 (commit aa14c1e) で 1 行修正

### 課題 4: 大規模 main マージのタイミングで untracked Step 4 成果物が残っていた

- **観測**: Step 4 進行中 (qa-design.md / qa-flow.md untracked) で `git merge origin/main` を実行。main マージ自体は前提崩壊を 4 件持ち込んだが、untracked 成果物の取り扱い (破棄 / コミットしてから差し戻し) を判断するための一時レポートを Main が作成 (`step4-main-merge-impact.md`)
- **発見ステップ**: Step 4 (進行中)
- **根本原因**: companion 2 サイクル (`2026-04-29-integrate-self-review-into-external` Self-Review 統合 / `2026-04-29-retro-cleanup` retrospective 集約) が並行進行しており、本サイクル進行中に main マージされる前提を Step 1 / Step 3 段階で想定していなかった。Step 1 着手時点では「Self-Review は健在 / docs/dev-workflow/ 前提 / retrospective サイクル内保存」だった
- **解消経路**: Plan D (ピンポイント差し戻し) を採用し、Step 1 / Step 3 / Step 4 を順次新規 Specialist で更新。一時レポートでユーザー判断 (案 D 採用) を確定後にリカバリ実行

### 課題 5: backward-compatibility reviewer の成果物作成漏れ

- **観測**: Step 7 で起動した 4 reviewer のうち `backward-compatibility` 観点 1 名は当初レポートファイルを作成せずチャット返却のみだった (Main が代替で `review/backward-compatibility.md` に書き出し済)
- **発見ステップ**: Step 7 集約時
- **根本原因**: Specialist 起動入力での「成果物パス必須」明示が弱かった可能性。`specialist-common/SKILL.md` § 3 (出力契約) には記述があるが、reviewer 起動時に Main から再強調しなかった
- **解消経路**: Main がチャット出力を `review/backward-compatibility.md` に書き出し、後段ステップでは正規の review レポートとして参照

## 次回改善案

### プロセス改善

- **task-plan で path 置換のような「機械的だが対象範囲が広い」タスクを定義する場合は、対象ファイルを `find` / `grep` で網羅的に列挙してから定義する**: 本サイクルでは `ggrep -rln "docs/dev-workflow/" plugins/dev-workflow/` を実行すれば 29 ファイル / 32 箇所が事前に判明していた。planner が task-plan 作成時に「対象範囲が機械的に列挙できるタスク」を識別する判定基準を持つ
- **qa-design.md の grep ベース TC は実際の対象ファイル状態で動作確認する**: TC-029 / TC-030 (frontmatter 多行) や TC-017 / TC-028 (git rename detection の pathspec) のような「観測手段が対象ファイル形式に依存する TC」は、qa-analyst が qa-design 確定前に最低 1 回サンプル実行する。ユーザー対話で「観測手段の確認」をゲートに含めても良い
- **大規模 main マージは Step 着手前に行う**: companion ブランチが並行進行している場合は、Step 1 着手前に `git merge origin/main` を完了させ、その時点での前提に固定する。Step 4 進行中のマージは「untracked 成果物の取り扱い」「Step 1 改訂の必要性判定」など複数の判断を同時に要求し混乱を招く
- **Plan D (ピンポイント差し戻し) を前提崩壊時の標準パターンとして dev-workflow に明記する**: 本サイクルで有効性が確認された案 D (Step 1 / 3 / 4 を順次 Specialist 新規起動で機械的更新) を、`dev-workflow/SKILL.md` のロールバック規約セクションに「companion マージ起因の前提崩壊時の推奨対応」として記載

### スキル改善

- **`shared-artifacts/templates/task-plan.md` (または `references/task-plan.md`)**: 「機械的だが対象範囲が広いタスクの定義時の注意」セクションを追加。`grep` / `find` での事前列挙、Step 8 Validation の事後検査だけでなく事前列挙の網羅性も task-plan 内で明示する旨を品質基準に追加
- **`shared-artifacts/references/qa-design.md`**: 「grep ベース TC の動作確認義務」を品質基準に追加。frontmatter / 多行 YAML / git rename detection など、対象ファイル形式に依存する観測手段は qa-analyst がサンプル実行する旨を明記
- **`plugins/dev-workflow/skills/dev-workflow/SKILL.md` のロールバック規約セクション**: 「companion マージ起因の前提崩壊時は Plan D (ピンポイント Specialist 差し戻し) を第一選択とする」記述を追加。Plan A (全面 soft rollback) / Plan C (Main 直接編集) との比較表を含める

### Specialist プロンプト改善

- **`intent-analyst`**: 起動時入力に「companion ブランチ並行進行の有無確認」を含める。並行進行中なら Step 1 着手前に main マージを推奨
- **`researcher`**: 該当なし (本サイクル研究 4 件はすべて適切に成果を生成)
- **`architect`**: 「path 置換のような機械的タスクは grep で対象範囲を網羅列挙してから design に書き込む」を作業手順に追加
- **`qa-analyst`**: 「grep / git diff 等の観測手段を含む TC は qa-design 確定前にサンプル実行する」を作業手順に追加
- **`planner`**: 「対象ファイル範囲が機械的に列挙できるタスクは `grep` / `find` で事前網羅し、対象数を task-plan に明記する」を作業手順に追加
- **`implementer`**: 該当なし (本サイクル T0-T15 全 16 タスクは仕様通り完遂)
- **`reviewer`**: 起動時に「成果物パス必須」を Main から再強調する運用ルール (本サイクルで `backward-compatibility` reviewer がチャット返却のみだった件への対処)
- **`validator`**: 該当なし (TC-029 / TC-028 の観測手段補正は `validation-report.md` のインライン記録でカバー、補助ディレクトリは Round 2 で廃止)
- **`retrospective-writer`**: 該当なし (本サイクルで再活性化なし、品質基準遵守)

## 再利用可能な知見

- **Plan D (ピンポイント差し戻し) はスコープ変化時のロールバックで有効**: 全面 soft rollback (Plan A) より軽く、Main 直接編集 (Plan C) より dev-workflow 原則に整合。Step N → Step 1 ロールバック後、Step 1 / 3 / 4 を順次新規 Specialist 新規起動で機械的更新するパターンは、companion マージ起因の前提崩壊一般に適用可能
- **Step 7 reviewer の Major 指摘 → Step 6 後発追加 → Step 7 再実行スキップ → Step 8 実測 のフロー**: 機械的修正の場合、Step 7 再実行より Step 8 Validation で実測する方が効率的。reviewer 指摘の性質 (機械的 vs 設計判断) を Main が見極めて選択する判断軸
- **集約形式 retrospective + `roadmap-` prefix**: dev-workflow 系 retrospective (`docs/retrospective/<identifier>.md`) と dev-roadmap 系 retrospective (`docs/retrospective/roadmap-<roadmap-id>.md`) を同一ディレクトリに集約しつつ命名衝突を回避するパターン。ADR 同様のフラット集約 + ID 名前空間の構造的分離は他プロジェクトでも応用可能
- **`progress.yaml.roadmap` ネスト構造**: フラット 2 フィールド (`roadmap_id` / `milestone_id`) より、ネスト構造 (`roadmap.id` / `roadmap.milestone.id`) の方が「`roadmap == null` で `milestone` 単独存在」の矛盾を構造的に排除できる。「上位概念がない場合に下位概念だけ存在し得ない」を表現する場合の設計パターンとして再利用可能
- **`grep -rln` ベースのスコープ事前検証**: path 置換 / ステップ番号置換 / 旧概念削除のような「機械的だが対象範囲が広い」タスクは、planner が `grep -rln` で事前網羅してから task-plan に対象数 + ファイルリストを書き込むことで取りこぼしを防げる
- **YAML 多行 frontmatter での grep 観測手段の落とし穴**: `description: > ... ` の多行 YAML 形式で記述された identifier 列挙を `ggrep -nE` 行内マッチで検査するとマッチしない。多行対応 (`-z`) または列挙数のカウント方式に切り替える必要がある
- **`git diff --find-renames` の pathspec 要件**: rename detection を機能させるには「source path と destination path の双方が pathspec に含まれる」必要がある。リネーム検証 TC では `-- new-path/ old-path/` の双方を指定する

## ユーザー承認ゲートの振り返り

7 件のユーザー承認ゲート (うち初期 2 件はユーザー対話、後段 5 件は離席中の auto 承認):

- **Step 1 (Intent Clarification, initial, 2026-04-29T02:30:00Z)**: ユーザー対話。schema 訂正後に承認 (`{roadmap.id, roadmap.milestone.id}` ネスト構造の採用、フラット案からの変更)
- **Step 3 (Design, initial, 2026-04-29T06:30:00Z)**: ユーザー対話。schema simplification (events 構造廃止、最小スキーマ + git 3-way merge 任せ) で承認
- **Step 1 (Intent Clarification, post-rollback revision, 2026-05-01T00:00:00Z)**: auto 承認。main マージ前提崩壊への追従 (9 ステップ移行 / docs path rename / retrospective 集約 / SC-12 baseline 再定義) を反映した改訂版を承認
- **Step 3 (Design, post-rollback revision, 2026-05-01T01:30:00Z)**: auto 承認 (離席中)
- **Step 4 (QA Design, 2026-05-01T02:30:00Z)**: auto 承認 (離席中)
- **Step 5 (Task Decomposition, 2026-05-01T03:00:00Z)**: auto 承認 (離席中)
- **Step 8 (Validation, 2026-05-01T10:00:00Z)**: auto 承認 (離席中)、14 SC 全件 PASS

却下ゲートはなし。後段 5 件の auto 承認は本サイクルの「最後まで進めて」指示に基づく仕様。Step 7 (External Review) は dev-workflow 仕様上 Main 判定ゲートで、ユーザー承認対象外。

## In-Progress ユーザー問い合わせの振り返り

- **件数**: 1 件
- **主要トピック**: `step4-main-merge-impact.md` (`/tmp/claude-501/dev-workflow/`) — main マージによる本サイクルへの影響評価とリカバリ案 (Plan A / B / C / D) の提示。Plan D (ピンポイント差し戻し) を採用するユーザー判断を引き出した

件数 1 は適正範囲。前提崩壊のような大規模スコープ変化は In-Progress レポートでユーザー判断を構造化することで、Specialist 復帰後の作業を機械的修正に絞り込めた点が良好。

## コスト / 時間

- **各フェーズの実時間 (タイムスタンプベース推定):**
  - Step 1 (initial): 約 2.5 時間 (ユーザー対話 + schema 訂正)
  - Step 2 (Research, 4 並列): 約 1 時間 (existing-skill-structure / retrospective-writer-reusability / resumption-protocol-adaptation / progress-yaml-concurrency)
  - Step 3 (initial): 約 3 時間 (代替案比較 + Open Questions 確定 + design.md 573 行)
  - **Plan D ロールバック発生** (2026-04-29T07:00:00Z, 約 30 分判断 + リカバリ準備)
  - Step 1 (post-rollback): 約 17 時間相当 (実態は離席中の auto 進行で 10 分程度)
  - Step 3 (post-rollback): 約 1.5 時間相当 (実態は auto 進行で 10 分)
  - Step 4 (QA Design): 1 時間 (qa-design.md 173 行 + qa-flow.md 182 行)
  - Step 5 (Task Decomposition): 30 分 (task-plan.md 310 行、T0-T12)
  - Step 6 (initial T0-T12): 4 時間 (13 commits 並列実行)
  - Step 7 (External Review, 4 並列): 1 時間
  - **Step 7 → Step 6 ロールバック** (2026-05-01T08:30:00Z)
  - Step 6 (re-activation T13-T15): 30 分 (3 commits)
  - Step 8 (Validation): 1 時間
  - Step 9 (Retrospective): 進行中
  - **合計:** 実時間 ~58 時間中、auto 進行は約 11 時間
- **Specialist 起動回数:**
  - Step 1: intent-analyst 2 (initial + post-rollback)
  - Step 2: researcher 4 並列
  - Step 3: architect 2 (initial + post-rollback)
  - Step 4: qa-analyst 1
  - Step 5: planner 1
  - Step 6: implementer 13 (T0 main 直接 + T1-T12) + 後発 implementer 3 (T13 main 直接 + T14 + T15) = 16 起動
  - Step 7: reviewer 4 並列
  - Step 8: validator 1
  - Step 9: retrospective-writer 1
  - **合計:** 32 起動 (うち Specialist 起動 30、main 直接 2 = T0 / T13)
- **並列度の実効:**
  - Step 2 Research: 4 並列で 4 観点を独立進行 (実効並列度 4)
  - Step 6 Implementation: T1-T12 を依存グラフに沿って Wave 化、Wave 1 (T1, T6) → Wave 2 (T2, T3, T4) → Wave 3 (T5, T7-T10) → Wave 4 (T11, T12) で並列度 5 まで活用
  - Step 7 External Review: 4 並列で 4 観点を独立進行 (実効並列度 4)
  - Step 6 re-activation T13-T15: 部分並列 (T14 / T15 同時、T13 は機械置換で main 直接) で並列度 2
- **コスト効率**: 前提崩壊リカバリで 2 ステップを再実行したが、Plan D により Specialist 数の増加 (+ intent-analyst 1 / + architect 1 = 2 増) で済み、対話ループ巻き戻しを回避。後発タスク T13-T15 も 30 分で完了し、サイクル全体の所要時間増は約 1 時間以内に収まった
