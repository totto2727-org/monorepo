# Intent Spec: Integrate Self-Review (Step 7) into External Review

- **Identifier:** 2026-04-29-integrate-self-review-into-external
- **Author:** totto2727 (intent-analyst Specialist が会話履歴から再構築)
- **Created at:** 2026-04-29T00:00:00Z
- **Last updated:** 2026-04-29T00:00:00Z

## 背景

現状の `dev-workflow` プラグインは 10 ステップ構成で、Step 7 (Self-Review) と Step 8 (External Review) が独立した連続ステップとして並ぶ。Self-Review は `self-reviewer` Specialist 1 体が implementer の全 diff を統合的にレビューし、明白な bug / Design 違反 / Intent Spec 未達見込みを早期検出する役割を担っている。

しかし直前サイクル `docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md` の以下の知見により、Self-Review を独立ステップとして残すコスト対効果に疑問が生じた:

- 「課題 / ループ回数の分析」表で **Step 5 ↔ Step 7 (External Review) が Round 3 で 13/16 件修正** という最大の手戻りを発生させていた一方、**Step 5 ↔ Step 6 (Self-Review) は Round 2 で Medium 4 件のみ** に留まり、Self-Review 単独では観点別の問題の大半を検出できなかった
- 同 retrospective「次回改善案 → プロセス改善」第 3 項目で、**「External Review を Step 6 (Self-Review) と同時または先行起動する」「Self-Review は『自前視点の追加観点』に絞る」** という改善案が提示された
- 「再利用可能な知見」節で **「External Review の 5 観点並列起動は Markdown 成果物でも効果がある」** ことが実証されており、観点別 reviewer を Self-Review より早期に投入できれば Round 数を削減できる見込み

ユーザー判断はこの改善案を一歩進めて、Self-Review ステップ自体を廃止し、その役割（実装直後の手戻りコスト削減 / 明らかな問題の早期検出）を External Review (Step 8) の `reviewer` 群に吸収する方針を選択した。Step 数は 10 → 9 に縮小し、後続ステップ番号 (8, 9, 10) を 7, 8, 9 に繰り上げる。

なお、本サイクルは `dev-workflow` プラグインの**自己改修**（meta-reflexive 開発）であり、変更対象は Markdown 成果物（スキル / エージェント / 成果物テンプレート / 成果物 reference / README / plugin.json）に限定される。実行可能コードは含まない。

## 目的

`dev-workflow` プラグインから Step 7 Self-Review を撤廃し、その責務を Step 7（旧 Step 8）External Review の `reviewer` 群に統合した 9-step 構成に再整理する。`specialist-self-reviewer` スキル / `agents/self-reviewer.md` / `shared-artifacts` の `self-review-report.md` 関連 (template + reference) を削除し、外部レビューが「観点別深掘り」と「全体整合性チェック（旧 Self-Review の役割）」を兼ねる形にスキル本文を更新する。プラグインを横断的に grep して旧 Step 番号と self-review 表記の残存をゼロにし、別セッションのユーザーが新フローのみで作業を継承できる状態にする。

## スコープ

### 削除対象

- `plugins/dev-workflow/skills/specialist-self-reviewer/` ディレクトリ全体（SKILL.md とその他ファイル）
- `plugins/dev-workflow/agents/self-reviewer.md`
- `plugins/dev-workflow/skills/shared-artifacts/templates/self-review-report.md`
- `plugins/dev-workflow/skills/shared-artifacts/references/self-review-report.md`

### 更新対象（Step 7 削除 + ステップ番号繰り上げ + Self-Review 役割吸収）

- `plugins/dev-workflow/skills/dev-workflow/SKILL.md`
  - Step 一覧テーブル（L135 付近）を 9 行に縮小
  - Step 7 Self-Review セクション（L398–L464 付近）を削除
  - 旧 Step 8 External Review セクションを Step 7 に番号変更し、本文に「Self-Review が担っていた『全体整合性チェック』『implementer 直後の手戻り抑止』を本ステップで吸収する」旨と運用指針を追記
  - 旧 Step 9 Validation → Step 8、旧 Step 10 Retrospective → Step 9 に再番号化
  - フロー図 (L112 付近の ASCII)、コミット規約表 (L731)、並列度表 (L789)、ロールバック早見表 (L829–L835) を 9 ステップ構成に更新
  - Step 6 ↔ Step 7 ループ説明（L437–L464）を「Step 6 ↔ Step 7 (External Review)」のループ構造として再構成（旧 Self-Review ループのナレッジは保ちつつ External Review の運用に吸収）
- `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md`
  - 担当ステップを Step 7 (External Review) に更新
  - description / 本文に「全体整合性チェック（旧 Self-Review の責務）」と「観点別深掘り」の両方を扱う旨を明記
  - 「Self-Review と同時 or 先行起動を許容する」のような旧前提を削除し、Self-Review 言及を消す
  - 「1 観点 1 reviewer」原則は維持しつつ、Round 1 で High 指摘を全観点で検出 → Round 2 で実装修正、というループ運用を本文に追記
- `plugins/dev-workflow/skills/specialist-validator/SKILL.md`
  - 担当ステップを Step 8 (Validation) に更新
  - description / Do NOT use for から `specialist-self-reviewer` 言及を削除
- `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md`
  - 担当ステップを Step 9 (Retrospective) に更新
  - description / 本文の `specialist-self-reviewer` 言及・Self-Review レポート参照を削除
  - 「ループ回数」「Step 6 ↔ Step 7 の往復」表現は External Review 観点で再記述
- `plugins/dev-workflow/skills/specialist-implementer/SKILL.md`
  - description / 本文の `specialist-self-reviewer` 言及を `specialist-reviewer` に統合
  - 「自己レビュー（specialist-self-reviewer の領域）」を「外部レビュー（specialist-reviewer の領域）」等に修正
- `plugins/dev-workflow/skills/specialist-common/SKILL.md`
  - L5 / L14 付近の Specialist 名列挙から `self-reviewer` / `specialist-self-reviewer` を削除
- `plugins/dev-workflow/skills/specialist-intent-analyst/SKILL.md`
  - description の `specialist-self-reviewer` 言及を削除
- `plugins/dev-workflow/agents/retrospective-writer.md`, `agents/reviewer.md`, `agents/validator.md`
  - description / 本文の Self-Review 言及・Step 番号を 9-step 構成に更新
- 残り全 agents (`agents/architect.md`, `implementer.md`, `intent-analyst.md`, `planner.md`, `qa-analyst.md`, `researcher.md`)
  - 本文中の「Step 7 = Self-Review」前提や Step 番号参照があれば 9-step 構成に更新（grep で確認）
- `plugins/dev-workflow/skills/shared-artifacts/SKILL.md`
  - 成果物一覧テーブル（L52 付近）から `self-review-report.md` 行を削除し、後続行（review-report / validation-report 等）の番号と Step 列を再付番
  - 保存構造 ASCII 図（L125 付近）から `self-review-report.md` を削除し、`review/` を Step 7 へ更新
- `plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml`
  - `artifacts.self_review` フィールドを削除
  - コメント内の Step 番号 (`Step 8 Review`) を `Step 7 Review` に更新
- `plugins/dev-workflow/skills/shared-artifacts/templates/TODO.md`
  - `Active Steps: Step 6〜7 (Implementation / Self-Review)` を `Active Steps: Step 6〜7 (Implementation / External Review)` に更新（または同等の表現に改訂）
  - `re_activations` コメント・コミット例の `self-review feedback` を `external-review feedback` 等に更新
- `plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md`
  - `self_review` フィールドの説明行を削除し、`review` の Step 番号を 7 に更新、validation を 8、retrospective を 9 に更新
- `plugins/dev-workflow/skills/shared-artifacts/references/todo.md`
  - 「Self-Review High 指摘」表現を「External Review High 指摘」に更新（再活性化トリガとしての役割は維持）
- `plugins/dev-workflow/skills/shared-artifacts/references/implementation-log.md`
  - `self-review-report.md` への出力先記述を `review/<aspect>.md` 等に更新
  - 「Self-Review および Retrospective の材料」「Self-Review で確認され」を External Review 表現に更新
- `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md`
  - 「Step 6 ↔ Step 7」のループ表は External Review 表現に更新
  - `self-review-report.md` の参照を `review/<aspect>.md` に更新
- `plugins/dev-workflow/skills/shared-artifacts/references/review-report.md`
  - 「Self-Review レポート（Step 7）とは別層」「Self-Review（全体整合性）とは別層」の記述を、Self-Review 廃止・吸収の文脈に書き換え（External Review が両役割を担う旨）
  - 担当ステップを Step 7 に更新
- `plugins/dev-workflow/skills/shared-artifacts/references/validation-report.md`
  - 担当ステップを Step 8 に更新
- `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md`, `templates/retrospective.md`
  - Step 番号（Step 8 → Step 7、Step 9 → Step 8、Step 10 → Step 9）の更新と、`self_reviewer_improvement` プレースホルダの削除
- `plugins/dev-workflow/skills/shared-artifacts/templates/retrospective.md`
  - `Step 6 ↔ Step 7` ループ表 / `Step 8 → Step 6` ロールバック表 / `self_reviewer_improvement` フィールドを 9-step 構成へ書き換え
- `plugins/dev-workflow/skills/shared-artifacts/templates/qa-design.md`, `references/qa-design.md`, `references/qa-flow.md`, `references/intent-spec.md` 等
  - `Step 9 validator` / `Step 9 で実測` の番号を Step 8 に更新（grep で発見した全箇所）
- `plugins/dev-workflow/README.md`
  - 「ten specialist subagents」「flat 10-step lifecycle」を 9 specialist / 9-step に更新
  - ステップ列挙「1. Intent → ... → 7. Self-Review → 8. External Review → 9. Validation → 10. Retrospective」を「1. Intent → ... → 6. Implementation → 7. External Review → 8. Validation → 9. Retrospective」に変更
  - AI-DLC 比較段落の「Self-Review, External Review」を「External Review」（または「External Review (which absorbs the role of an internal self-review)」のような統合表現）に変更
- `plugins/dev-workflow/.claude-plugin/plugin.json`
  - description の `flat 9-step lifecycle (... → Self-Review → External Review → ...)` を `flat 9-step lifecycle (Intent → Research → Design → QA Design → Task Decomposition → Implementation → External Review → Validation → Retrospective)` に更新（旧 description の 9-step は Self-Review を含めた古い記述で、現状の 10-step とも齟齬がある typo。本サイクルで正しい 9-step に正規化する）

### スコープ運用

- 影響範囲は `plugins/dev-workflow/` 配下のみ
- 既存の他成果物 (`docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/` / `2026-04-26-add-qa-design-step/` 等の過去サイクル成果物) は遡及修正しない（完了済み履歴として保持）

## 非スコープ

- 過去サイクル成果物 (`docs/dev-workflow/2026-04-*/`) の遡及修正
- External Review 観点（security / performance / readability / test-quality / api-design 等）の再定義 — 既存セットを維持
- 新たな Specialist の追加（`reviewer` / `validator` / `retrospective-writer` 等の既存 Specialist は維持）
- 別プラグイン（`plugins/totto2727/`, `plugins/moonbit/` 等）への波及修正
- `dev-workflow` プラグインの実行可能コード化（プラグインは Markdown のみ）
- マーケットプレイス公開の方針決定
- 観点別 reviewer の並列度上限の変更
- ステップ削除に伴うフェーズ概念の再導入（フラット step リストを維持）
- ADR の新規起票（本変更は dev-workflow プラグイン内のスキル責務再配置であり、横断的決定ではないため `design.md` で記録する）

## 成功基準

ファイル削除と更新の達成度を観測可能な形で計測する。`<root> = plugins/dev-workflow/`、コマンドは monorepo ルートから実行する前提。

### 削除確認

1. `test ! -d plugins/dev-workflow/skills/specialist-self-reviewer` が真（ディレクトリ非存在）
2. `test ! -f plugins/dev-workflow/agents/self-reviewer.md` が真
3. `test ! -f plugins/dev-workflow/skills/shared-artifacts/templates/self-review-report.md` が真
4. `test ! -f plugins/dev-workflow/skills/shared-artifacts/references/self-review-report.md` が真

### 残存表記の根絶

5. `grep -rnE -i 'self[-_]review|Self-Review' plugins/dev-workflow/` の結果が **0 件**（大文字小文字・ハイフン・アンダースコア混在も含めて全消し）
6. `grep -rnE 'self-reviewer|specialist-self-reviewer' plugins/dev-workflow/` の結果が **0 件**
7. `grep -rnF 'Step 10' plugins/dev-workflow/` の結果が **0 件**（旧 Step 10 = Retrospective が Step 9 に繰り上がる）
8. `grep -rnE 'Step 8 \(Validation\)|Step 9 \(Retrospective\)' plugins/dev-workflow/` の検出結果が、旧番号（`Step 9 (Validation)` / `Step 10 (Retrospective)`）と二重存在しない（grep -rnE 'Step (9|10)' で発見される行は ascii 図中の枠数字など正当な用途のみであることを目視確認 — 仮に検出されても `Step 9 (...)` `Step 10 (...)` のステップ参照表記は 0 件）

### 構造的完全性

9. `plugins/dev-workflow/skills/dev-workflow/SKILL.md` のステップ一覧テーブルが 9 行で、Step 7 が `External Review` / `reviewer` × N（観点並列）/ Gate=Main / 主要成果物に `review/<aspect>.md` を持つ
10. `plugins/dev-workflow/skills/dev-workflow/SKILL.md` のロールバック早見表に Step 7 (External Review)、Step 8 (Validation)、Step 9 (Retrospective) のエントリが存在し、旧 Self-Review 由来の「Step 7」エントリ（High 指摘 → Step 6 等）は External Review に統合された形で記載されている
11. `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の本文に「Self-Review が担っていた全体整合性チェック」「implementer 直後の手戻り抑止」を吸収した旨が明記されている（grep で「全体整合性」または「整合性」キーワードが検出される）
12. `plugins/dev-workflow/skills/shared-artifacts/SKILL.md` の成果物一覧テーブルから `self-review-report.md` 行が削除され、行番号が連番（欠番なし）で再付番されている
13. `plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml` に `self_review:` フィールドが存在しない（`grep -nE '^\s*self_review:' plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml` が 0 件）

### メタ整合性

14. `plugins/dev-workflow/README.md` が 9-step 構成と 9 specialist subagents を反映（specialist 数の数値・ステップ列挙が一貫）
15. `plugins/dev-workflow/.claude-plugin/plugin.json` の description が 9-step 構成かつ Self-Review 言及なし
16. `plugins/dev-workflow/agents/` 配下に 9 ファイル存在し（self-reviewer.md 削除後）、各 description / 本文に Self-Review 言及がない（成功基準 5 でカバー）
17. dev-workflow / specialist-* スキル内のクロスリファレンス（`specialist-self-reviewer` / `self-review-report.md` 等）が他の現存スキル名 (`specialist-reviewer` / `review/<aspect>.md`) で正しく置換されており、リンク切れ（存在しないスキル名・存在しないパスへの参照）が新規発生していない（手動目視確認）

## 制約

### 技術的制約

- 全ファイルは Markdown / JSON / YAML のみ（実行コード非該当）
- 削除対象ファイルは `git rm` でステージし、削除コミットと更新コミットを分離可能な単位で運用する
- ステップ番号置換は順序依存:
  - `Step 10` → `Step 9`、`Step 9` → `Step 8`、`Step 8` → `Step 7` を**降順で**置換しないと連鎖二重置換が発生する
  - macOS 環境のため `gsed` を使用（`macos-cli-rules` スキル準拠）
  - ただし置換対象に `Step 6 ↔ Step 7` のような複合表現や ASCII 図の枠線数字 / 一覧表の数値があるため、機械的な一括置換ではなく Edit ツールで文脈ごとに置換することを推奨
- description 行は frontmatter 内 250 文字程度の制約あり（agent description / skill description）

### 規範的制約

- `dev-workflow` の基本方針（Main-Centric Orchestration / One-Shot Specialist / Gate-Based Progression / Artifact-Driven Handoff / Project-Rule Precedence）は全継承
- 既存 ADR `doc/adr/2026-04-26-dev-workflow-rename-and-flatten.md` のフラット構造（フェーズ概念非導入）を維持
- 過去サイクル成果物 (`docs/dev-workflow/2026-04-*/`) の遡及修正禁止
- monorepo 共通の memory rules: `gsed` 使用 / `2>&1` 不使用 / `vp run` 経由 / `as` 型アサーション禁止 (TS の場合) / git commit は sandbox 外実行
- ドキュメント言語: 既存スキル本文の日本語踏襲、frontmatter / template / agent description は英語または既存踏襲

### 組織的制約

- 作業者は totto2727（Main 兼 設計者）。本サイクルは単独実行
- レビュー単位は各ステップ完了時の Artifact-as-Gate-Review（ユーザー単独レビュー）
- 期限なし（ユーザーの判断ペースに合わせる）

## 関連リンク

- 直前サイクル retrospective: `docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md`（特に「課題 / ループ回数の分析」表と「次回改善案 / プロセス改善」第 3 項目）
- 既存 ADR: `doc/adr/2026-04-26-dev-workflow-rename-and-flatten.md`（フラット step リスト構造の根拠）
- 直前 step 追加サイクル: `docs/dev-workflow/2026-04-26-add-qa-design-step/intent-spec.md`（番号シフトと grep 検証パターンの先例）
- 既存スキル: `plugins/dev-workflow/skills/dev-workflow/SKILL.md`, `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md`, `plugins/dev-workflow/skills/specialist-self-reviewer/SKILL.md`
- 既存 shared-artifacts: `plugins/dev-workflow/skills/shared-artifacts/SKILL.md` および `templates/`, `references/` 全般

## 未解決事項

(主要意思決定はユーザー要求で確定済み。Step 2 Research / Step 3 Design / Step 4 QA Design で確認・決定する細部を以下に列挙)

- **External Review に「全体整合性観点」を独立 reviewer として追加するか、既存観点 reviewer に分散吸収するか**: design.md で決定。1 案として「`specialist-reviewer` の観点に `holistic` (旧 Self-Review 役割) を追加し、N 並列の 1 枠に必ず割り当てる」運用が考えられる。Self-Review が「全体俯瞰」を担っていたため、観点を 1 つ増やすほうが責務移転が明示的になる
- **External Review の指摘深刻度カテゴリ統合**: 旧 Self-Review は High/Medium/Low、旧 External Review は Blocker/Major/Minor を使っていた可能性。design.md で深刻度ラベルの統一基準を決定（特に旧 Self-Review の「High = Step 6 に戻す」と旧 External Review の「Blocker = Step 6 に戻す」のマッピング）
- **External Review ループ運用の詳細**: Round 1 で全観点 reviewer 並列起動 → High/Blocker があれば Step 6 に戻る、というループの上限回数（旧 Self-Review は 3 周で Step 3 ロールバック検討）と、新統合運用での閾値を design.md で確定
- **`specialist-reviewer` 並列起動時のスコープ重複防止**: 「全体整合性観点」と「security 観点」「readability 観点」で指摘が重複した場合の Main 側のマージ運用を design.md で言語化
- **TODO.md の `re_activations` カウンタ意味の更新**: 現状「Self-Review High 指摘で Step 6 に戻った回数」だが、新運用では「External Review High/Blocker 指摘で Step 6 に戻った回数」に変更。template / reference 双方の表現を統一
- **`progress.yaml` の `review` フィールド構造**: 現状 `review:` はリスト（観点別）。Self-Review 廃止に伴い `self_review` キーを削除するが、リスト構造そのものは維持で良いか、全体整合性観点を別フィールドに分けるかを design.md で決定
- **旧 Step 7 (Self-Review) のループ知見の保存先**: 「3 周以上ループしたら設計レベル疑い」の知見は External Review ループに移植すべきだが、retrospective.md の retrospective に記録するか、specialist-reviewer 本文に併記するかを design で決定
- **Markdown 成果物の grep 検証コマンドの最終形**: 成功基準 5–8 の grep 式（`-i` 大文字小文字無視 / 拡張子フィルタの有無 / 隠しディレクトリ除外）を validator スキル相当の検証ステップで確定。`.git/` 以下を含むことのないようパス指定を厳密化
- **agent description 文字数制限**: 既存 agents の description が 200–300 文字想定だが、Self-Review 言及削除後に「Do NOT use for」リストの圧縮が必要なケースがあるかを Implementation で確認
