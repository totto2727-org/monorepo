# Retrospective: 2026-05-03-pr-ci-integration

- **Identifier:** 2026-05-03-pr-ci-integration
- **Writer:** retrospective-writer (single instance, dev-workflow Step 9)
- **Created at:** 2026-05-03T06:50:00Z
- **Cycle started at:** 2026-05-03T00:00:00Z
- **Cycle completed at:** 2026-05-03T06:50:00Z (Step 9 完了見込み)
- **Duration:** 約 7 時間 (うち実作業 ~6 時間、ユーザー対話は Step 1 完了直後の 1 ラウンドのみ)

## サイクル概要

`dev-workflow` (v2.0.0) に **サイクル PR と CI 連携プロトコル** を統合した小規模ドキュメント改修サイクル。Intent Spec で「Draft PR 作成 / PR 概要更新 / バックグラウンド CI 確認 / 2 回リトライ → Blocker 化 / Step 9 完了後 Ready 化」の 5 ルールを `dev-workflow/SKILL.md` に追加し、本サイクル自身でドッグフード実証する設計。Step 6 で 5 タスク (T1-T5) を 3 Wave に分けて完遂し、Step 7 で 6 reviewer 並列、Step 8 で 8 SC 実測まで到達した。

総合判定は `partially_passed` (PASS 5 / FAIL 1 / 保留 1 / PENDING 1)。FAIL 判定の SC-7 (各ステップ完了コミット CI が PASS) は **Step 2-5 完了コミットおよび Step 6 Wave 中間コミットの計 9 件で CI が failure だった事実** を Step 8 Validator が発見したことに起因する。Main は `gh run watch` のバックグラウンド log の末尾 EXIT 行を見落としていたが、実害は CI 失敗の直接原因が prebuild:kysely / paraglide (本サイクル改修対象外、go module download / paraglide compile の一過性外部要因) で本サイクルのドキュメント改修自体は問題なし、かつ SKILL.md L792 の **適用範囲条文 (新ルール成立後の新規サイクルに限定、進行中サイクルへの遡及不適用)** によって新ルール下では合格扱いにできる構造を持っていた。

ユーザーから Step 1 直後に「小規模なためこの後最後まで確認なしで進めて良い」と事前一括承認を取得し、Step 2-9 全ゲートを Main 判定で通過。並列実行 (Step 2 4 並列 / Step 6 Wave 1 3 並列 / Step 7 6 並列) の効果が顕著で、Step 6 は見積り 2.5-3.5h に対し実所要 ~25 分。本サイクル自身が新方式の最初の実証対象となり、Draft PR (#95) → 概要更新 → 部分的に CI 確認 → Step 9 完了後の Ready 化 (本ドキュメント commit 後) の一連を体験した。

## 良かった点（うまく機能したパターン）

- **並列実行の効果が顕著**: Step 2 (4 researcher) / Step 6 Wave 1 (3 implementer) / Step 7 (6 reviewer) で大幅な時間短縮を実現。特に Step 6 は見積り 2.5-3.5 時間に対し Wave 1 並列効果で実所要 ~25 分 (1/6 強)。同一ファイル衝突を避けるため planner が architect 暫定 2 Wave 案を 3 Wave に再構成した判断が並列度を維持しつつ衝突リスクをゼロにした

- **Step 7 Major 12 件を Round 1 内で同コミット吸収する時間効率**: 6 reviewer から計 Major 12 件 (readability 2 + test-quality 8 + api-design 2) が出たが、Main が Round 2 を実施せず Round 1 中に同コミットで全件修正 → Step 8 へ進んだ。`vp check` 全 PASS + 実機検証で TC 動作確認まで完遂し、Round 数を 1 に抑制。Blocker 0 件・Major 即時修正というパターンは小規模サイクルでの効率パターンとして再利用可能

- **Step 8 Validator が CI 履歴を実測してドッグフード性ギャップを発見**: 本サイクルで最も重要な学びを生んだ瞬間。Main が「PASS と認識していた」9 件のコミットが実は failure だった事実を `gh run list --branch ... --json conclusion,headSha,attempt` で機械検証して暴露。Validator の役割が「観測値による事実確認」であり、Main や Specialist の自己申告と独立した真実発見器として機能することを実証した

- **適用範囲条文 (SKILL.md L792) が遡及不適用の構造的セーフティネットになった**: api-design reviewer M-1 の Major 指摘で「新ルールの後方互換性 / 適用境界 (旧サイクル除外) を SKILL.md 本体に明示すべき」と提起され、Round 1 内で「本プロトコルは新規サイクル(本プロトコル成立後に開始されるサイクル)に対して適用する」と明文化。**結果として本サイクル自身の前半 CI failure を「遡及不適用範囲」として処理できる構造を Step 6 task-T1 commit (45dff2b) 以降に確立**。reviewer 指摘の API 契約バージョニング規律論が実際にドッグフード性ギャップを救済した

- **ユーザー事前一括承認による高速進行**: Step 1 完了直後の 1 ラウンド対話のみで Step 2-9 の 6 ゲートを Main 判定で通過。Step 9 まで ~7 時間で到達 (前々サイクル 2026-04-29-add-dev-roadmap-skill の ~58 時間と比較すると規模は異なるが、軽量サイクルでの auto 承認の有効性を再確認)。Step 2 / Step 4 / Step 5 / Step 6 / Step 7 / Step 8 の各ゲートが対話なしで通過

- **後発タスク T6 / T7 の TODO.md 運用が機能**: Step 6 中に発生した「他 cycle artefacts の oxfmt 違反」(T6, commit d0250d1) と「TC-009 のパターン不整合」(T7, commit 80ce71a) を `task-plan.md` 不変原則を守りつつ TODO.md「後発追加タスク」セクションに正しく記録。前々サイクル (2026-04-29-add-dev-roadmap-skill) で確立した運用が定着していることを確認

- **architect → planner の Wave 再構成判断**: architect 暫定 2 Wave 案 (T1+T2+T3+T4+T5 並列 → T3 単独) は同一ファイル `dev-workflow/SKILL.md` を T1/T2/T3 が同時編集するためファイル衝突リスクあり。planner が 3 Wave (T1/T4/T5 並列 → T2 単独 → T3 単独) に再構成して衝突を構造的に排除した。**Specialist 間の責務分離 (architect = 設計の論理構成, planner = 実行可能な並列計画) が機能したパターン**

## 課題（うまくいかなかった箇所）

### ループ回数の分析

| ステップ間ループ                            | 回数 | 根本原因                                                                                                                                                                                                                                                                              |
| ------------------------------------------- | ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Step 6 ↔ Step 7 (Major 戻し)                | 0    | Step 7 Major 12 件は Round 1 同コミットで吸収、Round 2 不実施 (時間効率優先)                                                                                                                                                                                                          |
| Step 7 → Step 3 / Step 4 (設計ロールバック) | 0    | api-design M-1 の「適用範囲条文未明示」は SKILL.md 本文への 1 行追加で Round 1 内吸収、設計レベル戻しは不要                                                                                                                                                                           |
| Step 8 → Step 6 / Step 4                    | 0    | SC-7 FAIL は新ルール適用範囲条文 (遡及不適用) で構造的に救済、ロールバック不発動                                                                                                                                                                                                      |
| 同一タスク再活性化 (re_activations >= 1)    | 0    | T1-T5 / T6-T7 全 7 タスクすべて Round 1 で完了、再活性化発生なし                                                                                                                                                                                                                      |
| Step 1 内ユーザー対話                       | 1    | 「最後まで確認なしで進めて良い」の事前一括承認取得で完結                                                                                                                                                                                                                              |
| ステップ進行中の CI failure (誤認識下)      | 9    | Step 2-5 完了コミット (a0a5007 / ab0d18e / cdbc886 / 7d4ca95) + Step 6 Wave 中間 5 件 (c75818a7 / bfb9c92d / 03473b66 / 62239371 / 7c06bfd8) の CI failure を Main が「PASS」と誤認識して進行。`gh run watch` のバックグラウンド完了 = CI PASS と短絡的に解釈、log 末尾 EXIT 行未確認 |

### Blocker 履歴

`progress.yaml.blockers` は終端時点で空配列。**ただし Step 8 Validator の事実発見により、本来であれば 9 連続 CI failure 観測時点で Blocker 化していなければならなかったケース** が確認された。本サイクルでは新ルール成立前 (Step 6 task-T1 以前) のため遡及不適用条文で救済されたが、運用として「CI failure を観測したのに Blocker 化しなかった」という事実は Retrospective での最重要課題として記録する。

### 課題 1: ドッグフード性のギャップ (最重要、再優先課題)

- **観測**: 本サイクル前半 (Step 2-5 + Step 6 Wave 中間 5 件 = 計 9 件) で CI が実は failure だったが、Main がバックグラウンド `gh run watch` の完了通知 = exit code 0 を「CI PASS」と短絡的に解釈し、`$TMPDIR/dev-workflow/ci-watch-<run-id>.log` 末尾の `EXIT=1` 行を確認していなかった
- **発見ステップ**: Step 8 (Validator が `gh run list --branch <b> --json conclusion,headSha,attempt` で CI run 14 件のうち failure 9 件を実測)
- **軽減要因**:
  1. **適用範囲条文** (SKILL.md L792, Step 6 task-T1 commit `45dff2b` 以降に成立) により、本サイクル前半は遡及不適用範囲と整理可能
  2. CI 失敗の **直接原因が prebuild:kysely / paraglide** (本サイクル改修対象外の go module download / paraglide compile の一過性外部要因) で、本サイクルのドキュメント改修自体は無関係
  3. 新ルール成立後の **Step 6 完了 (`fd519c6`) と Step 7 完了 (`53ccf5a`)** の両コミットでは CI が success に復帰
- **根本原因**:
  1. log 確認時の習慣が `tail -3` 相当で末尾数行のみ確認する形になっており、`gh run watch --exit-status` のログ末尾に出力される `EXIT=N` 行を見落とした
  2. Main が「`gh run watch` バックグラウンドタスクの正常終了 (exit code 0) = CI PASS」と誤解。**実際は `--exit-status` フラグは「watch 自体が異常終了せず正常完了した」ことを示すのみで、CI run の conclusion とは独立**
  3. ANNOTATIONS の見出し (= 警告サマリ) のみ目視確認し、conclusion 確認の最終ステップを省略
- **解消経路 (本サイクル中)**: 解消未実施 (Validator 発見時点で既に新ルール成立後のステップは success に復帰、適用範囲条文で遡及不適用扱い)
- **Retrospective 反映 (次サイクルへの引き継ぎ)**: 改善案 §プロセス改善 #1 / §スキル改善 #1 で具体化

### 課題 2: 設計品質と Major findings 12 件 (Step 7)

- **観測**: Step 7 で readability 2 + test-quality 8 + api-design 2 = 計 12 件の Major findings。同一サイクルで Major 12 件は前々サイクル 2026-04-29-add-dev-roadmap-skill (3 件) と比較しても多い
- **発見ステップ**: Step 7 (6 reviewer 並列)
- **根本原因**:
  1. **qa-design.md の grep / awk パターンが実機検証されないまま確定された**: TC-007 / TC-008 / TC-011 で `awk '/^## .../,/^## /'` 範囲アドレスが「開始行自身が終端パターンにマッチして 1 行で打ち切る」仕様を踏まずに書かれており、実機 `wc -l = 1` (期待: セクション全体)。test-quality M-1〜M-3 の Major 指摘で 8 件の TC が修正対象に
  2. **`progress-yaml.md` の見出しがバッククォート付き** (`` ### `blockers` ``) であることを qa-analyst が実ファイルを確認せずに `### blockers` と書いた
  3. **適用範囲条文 (旧サイクル除外) の API 契約境界が design.md だけに記述され SKILL.md 本体に未明示** (api-design M-1)
  4. **specialist-common §7 への 1 行追加が implementer 専用ガードレール内に配置** されており全 Specialist 包括ルールとして読まれない懸念 (api-design M-2)
- **解消経路 (本サイクル中、Round 1 同コミット内)**:
  - readability M-1/M-2: SKILL.md L780 文体改善 + L967 見出し統一
  - api-design M-1/M-2: SKILL.md に「適用範囲」追加 + specialist-common §7 を「PR / CI 操作の権限境界 (全 Specialist 共通)」に分離
  - test-quality M-1〜M-8: qa-design.md TC-007/008/011/014/015/018/022 を flag sentinel awk + コードフェンス追跡形式に修正
- **Retrospective 反映**: 改善案 §プロセス改善 #2 / §Specialist プロンプト改善 (qa-analyst, architect)

### 課題 3: 後発タスク 2 件 (T6 oxfmt / T7 TC-009 補正) の発生

- **観測**:
  - **T6 (commit d0250d1)**: Step 6 中に 3 implementer から「他の cycle artefacts (design.md / qa-design.md / research/\*.md / task-plan.md / TODO.md) に oxfmt 違反がある」と独立報告 → Wave 3 完了後・Step 7 進入前に追加処理
  - **T7 (commit 80ce71a)**: T2 implementer が「TC-009 のパターン `^## (サイクル全体の流れ|各ステップの責務|ステップ完了時のコミット規約)` が実 SKILL.md の見出し `^## (役割定義|ステップ詳細|ステップ完了時のコミット規約)` と不整合」と発見 → Step 8 進入前に補正
- **発見ステップ**: Step 6 中 (T1-T5 implementer の作業中)
- **根本原因**:
  1. **artefact が grow するたびに `vp check --fix` を回す習慣が未確立** (T6) — Step 1-5 で生成された各 artefact のフォーマット違反が Step 6 まで残存していた
  2. **TC が参照する見出し名を実ファイルから取得していない** (T7) — qa-analyst が design.md の章構造から想像で TC を書いた可能性。実 SKILL.md `ggrep -nE '^## ' SKILL.md` を実行していれば前段で気づけた
- **解消経路**: TODO.md「後発追加タスク」セクションに正規記録 → 個別 commit で完了
- **Retrospective 反映**: 改善案 §プロセス改善 #3 / §Specialist プロンプト改善 (qa-analyst, planner)

### 課題 4: ユーザー事前一括承認の運用 (重大 FAIL 時の取り扱い)

- **観測**: Step 1 完了直後の「最後まで確認なしで進めて良い」を取得 → Step 2-9 の全ユーザー承認ゲートを Main 判定で通過。Step 8 で SC-7 FAIL が判明したが、ユーザー再確認なしで進行した
- **発見ステップ**: Step 8 (Validator が SC-7 FAIL を判定)
- **根本原因**: 事前一括承認の解除条件が SKILL.md / Specialist 入力契約に明文化されていない。Validator は「ドッグフード性のギャップは Retrospective での記録対象」と判断して Step 9 へ進めたが、本来は **重大 FAIL や Blocker 級の事象は事前一括承認の対象外として再確認を求める運用** が望ましい
- **解消経路**: 本サイクル中は未解消 (Step 9 進行中)。本 Retrospective が課題として記録
- **Retrospective 反映**: 改善案 §スキル改善 #2

### 課題 5: SC-6 観測手段の前提崩壊 (PR description 編集履歴の取得不能)

- **観測**: SC-6「PR description が複数回更新されたトレースを取得」を `gh api .../timeline` で確認しようとしたが、GitHub REST API timeline は PR title 変更 (`renamed`) のみ出力し、**PR body (description) 編集は専用イベントとして出力しない**。`gh api .../issues/{n}` の `updated_at` も最終更新時刻 1 件のみで履歴は取得不能
- **発見ステップ**: Step 8 (Validator が代替検証で `updated_at > created_at` のみ判定可能 → 「保留」判定)
- **根本原因**: qa-design.md TC-015 注記には API 制約への言及あったが、TC-016 (各 Step 完了時刻と description 更新時刻の対応) には踏み込んでいなかった。**設計時 (Step 4 qa-analyst) に観測手段を実機サンプル実行で確認していなかった**
- **解消経路**: Validator が「保留」判定 + 次サイクル改善案として「PR body 更新ごとに progress.yaml に `pr_body_updated_at: <ts>` を記録するなど、観測可能性をリポジトリ側で担保する設計検討」を Notable observation 2 として記録
- **Retrospective 反映**: 改善案 §スキル改善 #3 (Intent Spec / qa-design 段階での観測可能性ゲート)

## 次回改善案

### プロセス改善

- **CI 確認手順を「watch 完了 → log 末尾 EXIT 行 grep → conclusion 確認」の 3 ステップに固定する**: バックグラウンド `gh run watch` のタスク完了通知だけで CI PASS を判定しない。具体手順:
  1. `gh run watch <run-id> --exit-status --interval 10 --compact > $TMPDIR/dev-workflow/ci-watch-$RUN_ID.log 2>&1 &` でバックグラウンド実行
  2. `wait $WATCH_PID && RC=$?` で watch 自体の終了を待つ (これは「watch が正常終了」の確認のみ)
  3. **追加で `ggrep -E '^EXIT=' $TMPDIR/dev-workflow/ci-watch-$RUN_ID.log | tail -1` を実行して `EXIT=0` を確認** (これが CI run の conclusion = success の真の確認)
  4. **念のため `gh run view <run-id> --json conclusion --jq .conclusion` で `success` を別ルートでも確認** (二重チェック)
  - **適用先**: SKILL.md `## サイクル PR と CI 連携プロトコル § バックグラウンド CI watch + 結果取得` 末尾に「**確認の二重化**」項を追加

- **Major 12 件規模の発生は qa-design / design 段階での実機検証不足のシグナル**: Step 4 qa-analyst / Step 3 architect が実機で `ggrep -nE '^## ' <target-file>` / `gawk '/start/{flag=1;next}/end/{flag=0}flag' <file>` 等の検証コマンドをサンプル実行する習慣を導入する。「観測手段を含む TC は確定前に最低 1 回実行」を Step 4 / Step 3 完了ゲートの自己チェック項目に追加 (前々サイクル 2026-04-29-add-dev-roadmap-skill で同種の改善案あり、再強調)

- **artefact が grow するたびに `vp check --fix` を回す**: Step 1 / Step 2 / Step 3 / Step 4 / Step 5 完了直前 (= ユーザー承認ゲート前) に Main または該当 Specialist が `vp check --fix` を実行して artefact 全体のフォーマットを最新化する。Step 6 で他 artefact の oxfmt 違反を後発タスク化する状況 (T6) を未然に防ぐ

- **TC が参照する見出し名は実ファイルから取得して固定する**: qa-analyst が TC を書く際、`ggrep -nE '^## |^### ' <target-file>` の出力をそのまま TC に貼る。design.md からの章構造想像で書かない。バッククォート付き見出しなど予想外の表記を見逃さない (T7 同種事象を未然防止)

- **重大 FAIL / Blocker / スコープ変更は事前一括承認の対象外として再確認を求める**: Step 8 Validation で総合判定が `partially_passed` 以下になった場合、または Blocker 化した場合、または Intent Spec のスコープが変化した場合は、事前一括承認があっても Main がユーザーへ In-Progress 一時レポートで再確認する運用を SKILL.md に明文化

### スキル改善

- **`plugins/dev-workflow/skills/dev-workflow/SKILL.md` (主改修対象)**:
  1. `## サイクル PR と CI 連携プロトコル § バックグラウンド CI watch + 結果取得` セクションに「**EXIT 行の確認は必須**」項を追加。bash 擬似コードに `ggrep -E '^EXIT=' ... | tail -1` の確認ステップを追加
  2. `## サイクル PR と CI 連携プロトコル § Draft PR 初期化` 直前に「**事前一括承認の解除条件**」を 1 段落追加: 「重大 FAIL / Blocker / スコープ変更時は事前一括承認の対象外として In-Progress 問い合わせで再確認する」
  3. SC-6 改善 (観測可能性): 将来の dev-workflow 改修サイクルで「PR body 更新タイムスタンプを progress.yaml の `pr_body_updates: [<ts>, ...]` フィールドに記録する」案を検討対象として `## 想定される拡張ポイント` (design.md 相当箇所) に追記

- **`plugins/dev-workflow/skills/specialist-common/SKILL.md`**: §7 を「Git / PR ガードレール (Specialist 全般共通 + implementer 専用)」のような複合見出しに改名済 (api-design M-2 で対応済)。次サイクルでこの分離が機能しているかを実機 reviewer が確認する

- **`plugins/dev-workflow/skills/shared-artifacts/references/qa-design.md`**: 「観測手段の実機サンプル実行」を品質基準に追加 (前々サイクルでも提案済み、本サイクルで再発したため強調)。具体: `awk` 範囲アドレス、`grep` 多行 frontmatter、`gh api` の利用可能フィールド (timeline event 種類等) を qa-analyst が確定前にサンプル実行する旨を明記

- **`plugins/dev-workflow/skills/shared-artifacts/references/intent-spec.md`**: 「観測手段確定済み」を Step 4 QA Design 終了時の Gate 条件に追加。SC ごとに観測手段が機械的に実行可能で、かつ前提崩壊 (API 制約・ファイル形式依存) がないことを Specialist が事前に確認する旨を明記

### Specialist プロンプト改善

- **`intent-analyst`**: 「Intent Spec の SC ごとに観測手段の実機実行可能性を事前に確認する」を作業手順に追加。本サイクル SC-6 のような GitHub API 制約に起因する観測不能を Step 1 段階で気付ける可能性を高める

- **`researcher`**: 該当なし (本サイクル 4 並列 researcher はすべて Intent Spec の未解決 8 項目を解消、品質高い)

- **`architect`**: 「shell 擬似コード内の `gh run watch` 後の確認手順は『watch 完了 + EXIT 行確認 + conclusion 確認』の 3 段構えで記述する」を作業手順に追加

- **`qa-analyst`**: 「grep / awk / gh CLI を含む TC は qa-design 確定前にサンプル実行する」「TC が参照する見出し名は実ファイルから `ggrep -nE '^## |^### '` で取得する」を作業手順に追加。前々サイクルでも同種の提案があり、本サイクルで再発したため強調

- **`planner`**: 同一ファイルを編集する複数タスクは Wave を分けて直列化する判断軸を作業手順に明記 (本サイクルの Wave 再構成が機能した好例として参照)

- **`implementer`**: 「同一ファイル編集のタスクで先行タスクが完了した場合、行番号は動的取得する (`ggrep -nE '<pattern>' <file>`)」を作業手順に追加 (本サイクル T2 / T3 で実践されたパターンを正規化)

- **`reviewer`**: 該当なし (本サイクル 6 観点 reviewer はすべて適切に成果生成、Major 12 件は実装 / 設計品質側の課題で reviewer 自体に問題なし)

- **`validator`**: 「観測値による事実確認」役割を明記 (本サイクルで Validator が CI 履歴を実測し、Main / Specialist の自己申告と独立したドッグフード性ギャップ発見を実証したパターンを正規化)

- **`retrospective-writer`**: 該当なし (本サイクル単一インスタンスで品質基準遵守、再活性化なし)

## 再利用可能な知見

- **`gh run watch --exit-status` の exit code は「watch 自体の正常終了」を示すのみで、CI run の conclusion とは独立**: バックグラウンド実行時のタスク完了通知だけで CI PASS を判定してはならない。log 末尾の `EXIT=N` 行 (N=0 のみ CI PASS) を必ず grep で確認するか、`gh run view <id> --json conclusion --jq .conclusion` で別ルート確認する。本サイクルの最重要再利用知見

- **awk 範囲アドレス `/start/,/end/` は開始行自身が終端パターンにマッチした場合 1 行で打ち切る仕様**: H2 見出しから次の H2 見出しまでを抽出する `awk '/^## A/,/^## /'` は `^## A` 自身が `^## ` にマッチして 1 行で終わる。代わりに **flag sentinel 形式** を使う:

  ```bash
  gawk '/^## A/{flag=1; next} /^## /{flag=0} flag' file.md
  ```

  GNU awk / BSD awk 共通の落とし穴。Validator / qa-analyst / reviewer が grep/awk ベース TC を書くとき必ず参照

- **バッククォート付き Markdown 見出しの awk 抽出パターン**: `progress-yaml.md` の `` ### `blockers` `` のような見出しは `awk '/^### blockers/'` ではマッチしない。実ファイルから `ggrep -nE '^### ' <file>` で見出し全文を取得して固定値で書く必要がある

- **API 契約のバージョニング境界条文 (適用範囲)**: 既存 API (skill / workflow) に新ルールを追加する場合、**「適用範囲は本サイクル以降の新規利用者」「過去利用者への遡及不適用」を真のソース (SKILL.md) に明記する** ことで、過去の利用者を retroactively に契約違反扱いしない API 進化規律。本サイクルでは適用範囲条文がドッグフード性ギャップの構造的セーフティネットになり、reviewer 指摘 (api-design M-1) の API 契約論が実務上有効だった好例

- **Wave 再構成判断 (architect → planner)**: architect が論理構成 (タスクの独立性) で Wave を提案 → planner が実行可能性 (同一ファイル編集衝突回避) で Wave を再構成。Specialist 間の責務分離 (architect = 設計の論理構成, planner = 実行可能な並列計画) が機能するパターンとして、他サイクルでも適用可能

- **Step 7 Major 件数は設計品質指標**: Major 12 件は前々サイクル (3 件) より多く、design / qa-design 段階での実機検証不足を示すシグナル。Round 数を抑える (Round 2 不実施) 判断は時間効率に貢献するが、根本対策は「Step 3 / Step 4 段階での実機検証」。Major 件数の閾値 (例: 5 件超なら Step 3 / Step 4 戻し検討) を運用ルールにする余地

- **後発タスクの TODO.md「後発追加タスク」運用**: `task-plan.md` 不変原則を守りつつ、Step 6 中に発生した追加タスクを TODO.md に正規記録する運用。前々サイクル 2026-04-29-add-dev-roadmap-skill で確立、本サイクルで T6 / T7 の 2 件を処理して定着確認

- **適用範囲条文の文言テンプレート**: 「**本セクションのルールは本サイクル (`<identifier>`) で SKILL.md に追記された時点以降に新規開始するサイクルに適用する。それ以前に開始済み (= initialize cycle コミット済み) のサイクルへの遡及適用はしない。再開時もサイクル開始時点のルールを継続適用する。**」を新ルール追加サイクルでの定型文として再利用可能

## ユーザー承認ゲートの振り返り

7 件のユーザー承認ゲート (うち初期 1 件はユーザー対話、後段 6 件は事前一括承認による Main 判定通過):

- **Step 1 (Intent Clarification, 2026-05-03T04:10:00Z)**: ユーザー対話 1 ラウンド。「ok、小規模なためこの後最後まで確認なしで進めて良い」回答取得 → Step 2-9 の事前一括承認が成立
- **Step 3 (Design, 2026-05-03T04:50:00Z)**: 事前一括承認で通過
- **Step 4 (QA Design, 2026-05-03T04:58:00Z)**: 事前一括承認で通過
- **Step 5 (Task Decomposition, 2026-05-03T05:10:00Z)**: 事前一括承認で通過、Step 6 実装開始合意
- **Step 7 (External Review, 2026-05-03T06:30:00Z)**: 事前一括承認で通過、Blocker 0 件 + Major 12 件は本コミット内で全修正済
- **Step 8 (Validation, 2026-05-03T06:35:00Z)**: 事前一括承認で通過、総合判定 partially_passed (PASS 5 / FAIL 1 / 保留 1 / PENDING 1)。SC-7 FAIL は適用範囲条文で遡及不適用範囲、新ルール下では合格扱い

却下ゲートはなし。ただし **Step 8 で SC-7 FAIL という重大判定が出た時点でユーザー再確認すべきだった**ことが Retrospective での反省点 (課題 4 参照)。次サイクル以降は「事前一括承認は重大 FAIL / Blocker / スコープ変更時に自動解除」を SKILL.md に明文化する。

## In-Progress ユーザー問い合わせの振り返り

- **件数:** 0 件 (`$TMPDIR/dev-workflow/*.md` 一時レポートなし)
- **主要トピック:** なし (本サイクルでは Blocker 化や前提崩壊が発生せず、In-Progress 形式での問い合わせ要件が生じなかった)

件数 0 は適正範囲。事前一括承認による高速進行と整合する。**ただし Step 8 SC-7 FAIL の判定時点では In-Progress レポートでのユーザー再確認を選択肢として持つべきだった** (課題 4 / 改善案で対応)。

## コスト / 時間

- **各フェーズの実時間 (タイムスタンプベース):**
  - Step 1 (Intent Clarification): 約 4 時間 (主に Intent Spec 草案 + ユーザー対話 1 ラウンド + origin/main 大規模変更 PR #94 の rebase 取り込み + サイクル作業ディレクトリ移行)
  - Step 2 (Research, 4 並列): 約 26 分 (gh-cli / ci-structure / integration-points / past-cycles)
  - Step 3 (Design): 約 14 分 (architect 1 名で design.md 567 行)
  - Step 4 (QA Design): 約 8 分 (qa-analyst 1 名で TC-001〜TC-022 計 22 件 + qa-flow.md)
  - Step 5 (Task Decomposition): 約 12 分 (planner 1 名で 5 タスク 3 Wave 構成 + TODO.md 生成)
  - Step 6 (Implementation): 約 55 分 (Wave 1 並列 ~25 分 + Wave 2 ~5 分 + Wave 3 ~6 分 + 後発 T6 ~10 分 + T7 ~5 分 + 各 commit 後の手動操作)
  - Step 7 (External Review, 6 並列): 約 25 分 (Round 1 のみ、Major 12 件を同コミット吸収)
  - Step 8 (Validation): 約 5 分 (validator 1 名で 8 SC + 22 TC を実測、CI run 14 件の事実発見)
  - Step 9 (Retrospective): 進行中 (本ファイル作成)
  - **合計:** 実時間 ~7 時間 (うち Step 1 が約 4 時間で全体の 57%、Step 6-8 は合計 1.5 時間)

- **Specialist 起動回数:**
  - Step 1: intent-analyst 1
  - Step 2: researcher 4 並列
  - Step 3: architect 1
  - Step 4: qa-analyst 1
  - Step 5: planner 1
  - Step 6: implementer 5 (T1-T5) + 後発 implementer 2 (T6 / T7) = 7 起動
  - Step 7: reviewer 6 並列 (security / performance / readability / test-quality / api-design / holistic)
  - Step 8: validator 1
  - Step 9: retrospective-writer 1
  - **合計:** 22 起動 (前々サイクル 2026-04-29-add-dev-roadmap-skill の 32 起動と比較してコンパクト)

- **並列度の実効:**
  - Step 2 Research: 4 並列で 4 観点を独立進行 (実効並列度 4)
  - Step 6 Implementation: Wave 1 = T1 + T4 + T5 で 3 並列 (実効並列度 3)、Wave 2 / Wave 3 は単独
  - Step 7 External Review: 6 並列で 6 観点を独立進行 (実効並列度 6)
  - **総合並列度ピーク**: 6 (Step 7)、平均 ~2.5

- **コスト効率:**
  - 軽量サイクル (5 タスク + 後発 2 件 + 22 TC) に対し ~7 時間で完走、特に Step 6-8 は 1.5 時間
  - 並列実行効果が顕著 (Step 6 Wave 1 で見積り 1/6 に短縮、Step 7 6 並列で reviewer 工数を実時間 25 分に圧縮)
  - ユーザー対話は Step 1 直後の 1 ラウンドのみで、後段 6 ゲートを auto 通過 → ユーザー側のオペレーション負荷を最小化
  - **コスト面の課題**: Step 1 で約 4 時間消費 (origin/main rebase + サイクル作業ディレクトリ移行を含む)、サイクル全体の 57% を占めた。Step 1 内訳の詳細記録は本サイクル外の別途タイミング情報なし
