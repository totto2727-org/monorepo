# Retrospective: 2026-04-24-ai-dlc-plugin-bootstrap

- **Identifier:** 2026-04-24-ai-dlc-plugin-bootstrap
- **Writer:** retrospective-writer (Verification Step 9, single instance)
- **Created at:** 2026-04-24T18:30:00Z
- **Cycle started at:** 2026-04-24T13:00:00Z
- **Cycle completed at:** 2026-04-24T18:00:00Z
- **Duration:** 約 5 時間（Verification Step 9 含む）

## サイクル概要

本サイクルは **AI-DLC プラグイン自体を AI-DLC のワークフローで構築する**という meta-reflexive（再帰的）な試みだった。Intent Spec の目的「1 Main + N Specialist の 2 層構成で、全ステップ・成果物・コミット規約・中断再開プロトコルを文書化した claude-plugin を提供する」に対し、`plugins/ai-dlc/` 配下に 15 スキル（main-* 4 / specialist-* 10 / shared-artifacts 1）、9 agents、11 reference + 11 template の成果物仕様を整備して完了した。

Validation では 7/7 成功基準 PASS、External Review では Blocker 0 / Major 16（13 件 Construction 再活性化で修正、3 件 Retrospective に繰越）、Self-Review では Medium 4 件を Round 2 で全件修正。Claude Code の「Subagents cannot spawn other subagents」制約を Research 段階で特定できたことで、当初の 3 層（Main → Orchestrator → Specialist）案を早期に 2 層構成へ転換でき、設計の手戻りを最小化した。

逆算的再構築モードでの実行のため、実際のユーザー対話駆動の進行を事後に Artifact-as-Gate-Review の形に整形して記録した特殊性がある。次の実サイクルでこのワークフロー自体をドッグフーディングする形で Specialist プロンプトの実使用検証が想定される。

## 良かった点（うまく機能したパターン）

- **Research Step で Claude Code 制約を並列で先行調査した**: `claude-code-constraints.md` / `plugin-structure.md` / `existing-skills.md` / `ai-dlc-concept.md` を 4 並列で走らせ、3 層構成不可の制約を Design 開始直後（13:50Z）に Rollback できた。後続の Implementation をほぼ一発で確定させる基盤になった。
- **External Review を 5 観点 × 5 Specialist の並列起動で運用した**: security / performance / readability / test-quality / api-design を同時起動し、Major 16 件を 1 ターンで網羅的に抽出。その後 Step 5 再活性化で 13 件をバッチ修正（commit `7f1c0be` → `807d2d0`）し、観点横断レビューのコスト対効果が高かった。
- **shared-artifacts スキルに成果物仕様を集約した**: 11 reference + 11 template の Single Source of Truth 化により、main-construction/main-workflow からスキーマ重複（Self-Review #2）が発見できた。集約がなければこの指摘自体が生まれなかった可能性が高い。
- **Self-Review の Medium を Round 2 で即時修正する運用**: Verification まで待たず Construction 内で 4 件（T15–T18）を解消し、External Review の対象を「設計上の問題」に絞れた。
- **逐次コミット + GPG 署名の厳守**: `--no-gpg-sign` / `--no-verify` を一切使わず、各修正を追跡可能な状態で積み上げた。再開プロトコル（progress.yaml + TODO.md）の信頼性が担保された。

## 課題（うまくいかなかった箇所）

ループ回数が多かった箇所、Blocker の根本原因、想定外のコストが発生した箇所を記録する。

### ループ回数の分析

| ステップ間ループ                     | 回数 | 根本原因                                                                                                                   |
| ------------------------------------ | ---- | -------------------------------------------------------------------------------------------------------------------------- |
| Step 5 ↔ Step 6 (Self-Review)        | 1 (Round 2) | Medium 4 件はすべて「shared-artifacts 抽出時の参照先・真のソース確定漏れ」。設計時に「委譲する側（main-*）の情報を必ず真のソース側（shared-artifacts）にだけ残す」チェックリストがなかった。 |
| Step 5 ↔ Step 7 (External Review)    | 1 (Round 3, 13/16 件) | Major 指摘の 13 件は readability / api-design / security / test-quality の観点別に存在し、Self-Review の 1 観点的視点では検出困難だった。観点別 reviewer を事前並列投入すべきタイミングが Step 6 と Step 7 の 2 回に分散。 |
| Construction → Inception Step 3      | 2    | (1) Orchestrator を独立させる 3 層設計が Claude Code 仕様違反と判明（13:50Z）、(2) ADR を主要成果物にした設計が ADR スキルの粒度と合わず Design Document へ再定義（14:10Z）。 |
| Verification → Construction          | 0    | Validation で FAIL が出なかったため巻き戻しなし。ただし Major 3 件（performance）は次サイクル送りで deferred 扱い。 |
| T2 (main-workflow) の再活性化        | 2    | 3→2 層変更と Artifact-as-Gate-Review 原則導入の 2 度の書き直し。                                                             |
| T4 (main-construction) の再活性化    | 2    | TaskCreate と TODO.md 同期ルールの事後追加。タスク分解時に「Claude Code の内部 todo API との同期契約」が漏れていた。         |

### Blocker 履歴

- Blocker は 0 件だった。ただし設計段階の **Rollback 2 件**（progress.yaml `rollbacks[]` に記録）が実質的に Blocker 級の方向転換だった:
  - Rollback 1: 3 層構成 → 2 層構成（発生 / 解消: 2026-04-24T13:50:00Z、対応: Research で得た Claude Code 公式仕様を根拠に即時 Design 書き直し）
  - Rollback 2: ADR 主役案 → Design Document 主役案（発生 / 解消: 2026-04-24T14:10:00Z、対応: 既存 adr スキルの粒度（軽量意思決定用）を確認し、サイクル設計書としての役割分担を再定義）

### Deferred Major 指摘（次サイクル改善候補）

External Review Step 7 で Major 扱いとなった performance 観点の 3 件は、大規模リファクタリングが必要なため Retrospective に繰越:

- **M#1**: `main-workflow/SKILL.md` が 479 行で推奨上限 500 行の 96%。`references/` への切り出し（commit-policy / project-rule-integration / phase-transition）が必要。
- **M#2**: main-<phase> 3 スキルの冒頭に完全同文の boilerplate（継承宣言）が重複。差分記述スタイルへの統一が必要。
- **M#3**: `shared-artifacts/SKILL.md` と `main-workflow/SKILL.md` で保存構造 ASCII 図が重複。実体を shared-artifacts に一本化し、main-workflow は 1 行参照のみに変更。

## 次回改善案

具体的なアクション粒度まで分解する（「〜を改善する」ではなく「〜のときに〜する」）。

### プロセス改善

- **Design 段階で「委譲チェックリスト」を Artifact-as-Gate-Review 項目に追加する**: 「A スキルから B スキルへ委譲を宣言したとき、A に同じ情報のコピーが残っていないか grep で機械的に確認する」を design.md レビュー時のチェックリストに組み込む。Self-Review Medium #2 / #3 はこれで事前検出できた。
- **Research Step で「Claude Code 公式仕様レビュー」を必須サブトピックにする**: 公式仕様の制約（subagent 階層、description 長、hook イベント等）を必ず 1 topic として並列検索する。Rollback 1（3 層→2 層）の早期発見を再現可能にする。
- **External Review を Step 6 (Self-Review) と同時または先行起動する**: 5 観点別 reviewer を Self-Review 時点で並列起動し、Self-Review は「自前視点の追加観点」に絞る。これで Step 5 ↔ Step 7 の Round 3 (13/16 件修正) を Step 5 内の初回で吸収でき、再活性化コストを削減できる。
- **実装前に context window 予算を見積もる**: Construction 開始時に「Main が同時に読むスキルの累計行数」を算出（現在 1,268 行）、500 行 / スキルの個別制約だけでなく累計制約を事前設計する。performance Major 3 件はこれで予防可能。

### スキル改善

AI-DLC プラグインのスキル（workflow / inception / construction / verification）への具体的な改善提案。

- **対象: `main-workflow/SKILL.md`**: L329–411「ステップ完了時のコミット規約」を `main-workflow/references/commit-policy.md` に切り出す。本体は 2–3 行サマリ + リンクに置換。同様に L277–326「プロジェクト固有ルールとの関係」と L414–425「フェーズ遷移時の引き継ぎ」も references 化し、SKILL.md 本体を 300 行以下に圧縮。
- **対象: `main-{inception,construction,verification}/SKILL.md`**: 冒頭の「main-workflow を継承する」宣言文を全 3 ファイルで 1 行（「継承元: `main-workflow`。フェーズ固有事項のみ以下に記載」）に統一。詳細な継承ルール羅列は main-workflow 側の責務に戻す。
- **対象: `specialist-common/SKILL.md`**: L144–162 スコープ規律 / L175–183 Git コミット / L186–193 命令形・具体性の 3 セクションを `specialist-common/references/` に切り出し、本体は L1–143 のライフサイクル・入出力・失敗プロトコルに絞る。implementer 以外は Git セクションを読み込まない構造にする。
- **対象: `shared-artifacts/SKILL.md`**: L96–123 の保存構造 ASCII 図を真のソースとして確定し、main-workflow 側の重複記述を削除。
- **対象: `main-construction/SKILL.md` + `shared-artifacts/references/task-plan.md`**: Self-Review #4 で統一済みの「task-plan.md 不変運用」をレビュワーチェック項目として再確認する仕組み（Artifact-as-Gate-Review の標準チェック）を追加。
- **対象: specialist-* の description**: 200–300 文字に圧縮し、網羅的な Do NOT 列挙は本文の「このスキルが扱わないこと」セクションに移す。ai-dlc キーワードの衝突（main-workflow / main-<phase> 4 スキル同時活性化リスク）も description から "ai-dlc の <phase>" を削除して解消。

### Specialist プロンプト改善

- `intent-analyst`: 「観測不能な成功基準が混入したら早期に validator を事前相談起動する」手順を specialist-intent-analyst に追記。今回 validator 事前相談の余地はなかったが、実機能サイクルでは必須になる。
- `researcher`: 「Claude Code 公式仕様レビュー」を必須サブトピックとして researcher 入力契約に追加。4 並列の 1 枠を常に公式制約確認に割り当てる。
- `architect`: Design Document 作成時の「委譲チェックリスト」（真のソースが 1 つしかないことの grep 検証）を specialist-architect のアウトプット要件に追加。
- `planner`: task-plan に「同時読み込み context window 予算」欄を新設し、Wave 単位の累計行数を見積もらせる。今回の performance Major 3 件の予防。
- `implementer`: Git ガードレール（`--no-gpg-sign` / `--no-verify` / force push 禁止）は security M#1 で追記済み。今後は「shared-artifacts のような真のソース集約スキルに書き込む場合は、他スキルからの重複記述が残っていないか grep で確認してから commit」のルールも追加。
- `self-reviewer`: Medium 即時修正 Round 2 運用を手順として正式化（現状は暗黙）。Round 2 で修正した commit SHA を self-review-report.md に記録する欄を標準化。
- `reviewer`: 5 観点同時起動が効果的だったため、specialist-reviewer の入力契約に「Self-Review と同時 or 先行起動を許容する」条件を明記。
- `validator`: 「Markdown のみの成果物で自動テストなし」の静的観測パターン（ファイル存在 / 行数 / grep）をテンプレート化し、次回以降の Markdown プラグインサイクルで再利用可能にする。
- `retrospective-writer`: 入力に `$TMPDIR/ai-dlc/*.md` 一時レポートが含まれる前提は Self-Review #8 で指摘されたとおり。「同一セッション内実行が前提」か「Step 9 開始前に `docs/ai-dlc/<identifier>/_tmp-reports/` にコピー」の運用を specialist-retrospective-writer に明記する。

## 再利用可能な知見

他のサイクル・他のプロジェクトでも役立ちそうな学び。メモリや CLAUDE.md への反映候補を含む。

- **Meta-reflexive 開発（自分自身を自分のワークフローで作る）は、Research を極端に先行させると最大効果を発揮する**: プラットフォーム制約（今回は Claude Code の subagent 階層）を Design 前に把握できるかで、Rollback 1 回あたり 10–30 分のコスト削減に直結する。
- **shared-artifacts のような「真のソース集約スキル」を独立させる設計パターン**は、Specialist と Main が同じ仕様を参照する構造全般に応用可能。ただし集約しただけでは委譲元にコピーが残るため、「grep で機械的に重複検出」を運用に組み込むのが必須。
- **External Review の 5 観点並列起動**（security / performance / readability / test-quality / api-design）は、コードレビューだけでなく Markdown 成果物でも効果がある。skill-reviewer を持つプラグインなら同じパターンをそのまま流用可能。
- **CLAUDE.md への反映候補**: 「新プラグイン作成時は最初に `plugins/ai-dlc/skills/main-workflow/SKILL.md` の設計原則（Artifact-as-Gate-Review / Commit-Based Resumability / Main-Centric Orchestration）を参照する」旨の 1 行を追加可能。ただし本プラグインが実運用に入ってからでよい。
- **GPG 署名と `--no-verify` 禁止の厳守**は逆算再構築モードでも維持可能。逆算時でも hook が動作することを確認した（実害なし）。

## ユーザー承認ゲートの振り返り

- **Step 1 (Intent Clarification)**: approved（2026-04-24T13:30:00Z）。逆算再構築のため対話による確定は取らず、会話冒頭の要求定義から暫定承認。**教訓**: 次の実サイクルでは明示的な「Intent Spec レビュー」ラウンドを設ける。
- **Step 3 (Design)**: approved（14:00:00Z）。複数ラウンドのフィードバックで 3→2 層化、shared-artifacts 抽出、コミット規約、ADR との使い分けが段階的に確定。**教訓**: 「Main / Specialist 分離」のような根本設計はユーザー対話で 3–5 ラウンドかかる前提でタスク計画を組む。
- **Step 4 (Task Decomposition)**: approved（14:15:00Z、暗黙承認）。タスク分解の明示承認は取らず作業進行で暗黙承認。**教訓**: task-plan.md レビューゲートは次サイクルで明示的に運用する。Task Wave 単位の accept を Artifact-as-Gate-Review で取る。
- **Step 7 (External Review Major Findings)**: approved with conditions。ユーザー指示で「13 件修正、3 件 Retrospective 繰越」の判断。**教訓**: Major 全件修正か選択的修正かの判断フレームワーク（工数 vs 影響度マトリクス）を specialist-reviewer のアウトプットに含めるよう改善。
- **Step 8 (Validation)**: passed（18:00:00Z）。7/7 PASS で却下なし。**教訓**: Markdown 成果物では静的観測で十分 Validation 可能であることを実証。

## In-Progress ユーザー問い合わせの振り返り

- **件数:** 0（明示的な `$TMPDIR/ai-dlc/*.md` 一時レポートなし）
- **主要トピック:** 本サイクルは逆算再構築モードで、対話中の判断要請はユーザーとの直接会話で解消されたため、形式化された In-Progress 問い合わせは発生しなかった。
- **解釈:** 0 件は「Intent Spec が十分明確だった」を意味するというより「逆算モードでは In-Progress 形式に落とす必然性がなかった」を意味する。次の実サイクルでは、対話内の判断要請を**意識的に** `$TMPDIR/ai-dlc/<timestamp>.md` として一時ファイル化する運用に切り替え、Retrospective 入力として利用可能にする。

## コスト / 時間

- **各フェーズの実時間:**
  - Inception（Step 1–4）: 13:00Z–14:15Z = **75 分**（Rollback 2 件含む）
  - Construction（Step 5–6）: 14:15Z–16:45Z = **150 分**（Round 2 Medium 修正含む）
  - Verification（Step 7–9）: 16:45Z–18:30Z = **105 分**（External Review 並列 + Step 5 再活性化 13 件修正 + Validation + Retrospective）
  - **合計: 約 5.5 時間**
- **Specialist 起動回数:**
  - Research Step: 4 並列（intent-analyst 扱いの背景調査含む）
  - External Review Step 7: 5 並列（security / performance / readability / test-quality / api-design）+ 追加の詳細化で合計 24 並列 review agents 相当のバッチ
  - Step 7 の reviewer 起動: 5
  - Step 8 validator: 1
  - Construction 実装は Main 直接（Specialist 非起動）
  - **合計: 約 30 エージェント起動（並列バッチ含む）**
- **並列度の実効:**
  - Research: 4/4（理論上限）
  - External Review: 5/5（理論上限）
  - Step 5 再活性化修正 13 件: シーケンシャル実行（並列化余地あり、次回はファイル単位で並列化）
  - **効果:** 並列化可能な箇所（Research と Review）では確実に活用できた。修正作業の並列化は次回改善項目。
- **コスト / 効果:**
  - 5.5 時間で 15 スキル + 9 agents + 22 成果物仕様ファイル + 全 shared-artifacts を整備
  - Rollback 2 件で約 20 分、Round 2 Medium 4 件修正で約 10 分、Step 5 再活性化で約 30 分のロス
  - **全体のロス率: 約 18%**（次サイクルでは Design 段階のチェックリスト導入で 10% 以下を目標）
