# Intent Spec: Retrospective Cleanup — 2 過去サイクルの残提案項目の段階的反映

- **Identifier:** 2026-04-29-retro-cleanup
- **Author:** intent-analyst Specialist (auto モード、Main からの初期要求を要約・確定)
- **Created at:** 2026-04-29T10:00:00Z
- **Last updated:** 2026-04-29T10:00:00Z

## 背景

`dev-workflow` プラグインは過去 3 サイクルのメタ改修を経て現在の 9-step / 9 specialist 構成に到達した。各サイクルの retrospective には次サイクル送りとなった「残提案項目」が累積しており、本サイクルはそれを 1 サイクルにまとめて消化する **メタ改修第 4 弾** に位置付けられる。

参照対象 retrospective:

- `docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md`
  - 「課題 / Deferred Major」: `main-workflow/SKILL.md` 479 行 (M#1)、main-{inception,construction,verification} の boilerplate 重複 (M#2)、`shared-artifacts/SKILL.md` ↔ `main-workflow/SKILL.md` の保存構造 ASCII 図重複 (M#3)
  - 「次回改善案 / スキル改善」: `specialist-common/SKILL.md` の L144–162 / L175–183 / L186–193 を `references/` 切り出し、specialist-* description の 200–300 文字圧縮
  - 「次回改善案 / Specialist プロンプト改善」8 件 (intent-analyst / researcher / architect / planner / implementer / self-reviewer / reviewer / validator / retrospective-writer)
- `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md`
  - 「次回改善案 / プロセス改善」: planner reference に `shared-artifacts/references/*` 全件スキャンルール、`progress.yaml` 編集時の運用統一、gsed placeholder 規約 (implementer reference)、大規模修正タスクのサブタスク分解推奨
  - 「次回改善案 / スキル改善」 + 「Specialist プロンプト改善」: researcher の言語スキル棚卸し / architect の代替案 3-5 案推奨 / reviewer の backward-compatibility / validator のバッチスクリプト化 / implementer の placeholder ベスプラ等
- `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md`
  - 「次回改善案 / プロセス改善」: gsed `-e` 連鎖の禁止 + 2-phase placeholder ルール、メタサイクル baseline commit の明示特定、design.md 章節 ↔ template/reference の機械的紐付け
  - 「次回改善案 / Specialist プロンプト改善」: holistic 観点の Round 1 必須チェック、validator の deprecation 文書化 vs grep 検出のトレードオフ など

直前サイクル `2026-04-29-integrate-self-review-into-external` で既に対応済みの項目（**本サイクル非対象**）:

- Self-Review 削除 + External Review への holistic 観点統合
- 深刻度ラベル統一 (旧 Self-Review High/Medium/Low → External Review Blocker/Major/Minor)
- 3 周ロールバック規則の reviewer 移植
- `backward-compatibility` 観点の holistic 吸収
- 機械検証バッチスクリプト化（design.md / validation-report.md の grep コマンド集合）
- `self_reviewer_improvement` フィールド削除
- `qa-analyst` Specialist プロンプト改善欄の追加

また、以下は既に物理的に存在しないため**非スコープ**:

- 旧 `main-{inception,construction,verification}` 3 スキル（既にフラット化で削除済み、boilerplate 重複問題は霧散）
- `ai-dlc` キーワード衝突（既に `dev-workflow` 改名で解消）
- `main-workflow/SKILL.md`（既に `dev-workflow/SKILL.md` にリネーム済み。820 行 / 3,733 語であり skill-reviewer G3 (5,000 語以下) に違反していないため本サイクルでは圧縮対象としない）

本サイクルは `dev-workflow` プラグインの**自己改修**（meta-reflexive 開発）であり、変更対象は Markdown のみ。実行可能コードを含まない。

## 目的

3 つの retrospective に蓄積した残提案のうち、**`plugins/totto2727/skills/skill-reviewer/SKILL.md` のルール (G1-G7) に違反している項目および新規追加価値のある運用ルール** を選別して反映する。

skill-reviewer ルールへの照合結果、現状の dev-workflow プラグインは以下の通り **構造的違反なし**:

- **G2 #5 (description ≤ 1024 文字)**: 全 9 specialist + specialist-common が 410-775 文字で違反なし
- **G3 / G7 (SKILL.md 5,000 語以下)**: 最長の `dev-workflow/SKILL.md` でも 820 行 / 3,733 語で違反なし。他全ファイルも違反なし

そのため本サイクルは **構造的圧縮 (行数 / description) を含めず**、Step 1 ユーザーゲートでの個別評価を経て**3 件の Specialist 本文修正 + 1 件の ADR 起票 (A-4 のみ) + retrospective 保存場所と削除ポリシーの workflow 構造変更**に絞る:

1. **A-2 (dev-workflow/SKILL.md)**: 「Report-Based Confirmation for In-Progress Questions」セクションのレポート最小構成記述に「**選択肢と根拠は 3-5 案推奨**」を追記 (計画段階の全 Specialist が参照可能な共通プロトコルとして 1 箇所に集約)
2. **A-5 (specialist-reviewer)**: 「観点別のレビュー指針」に欠落していた `holistic` 小節の新設
3. **A-8 (specialist-retrospective-writer)**: 再活性化タスクの SHA 列挙手順の追加
4. **ADR の起票 (A-4 のみ)**: researcher のプロジェクト固有スキル棚卸し提案を「自動ロードに期待し将来再検討」と判断した経緯を `docs/adr/` 配下に新規 ADR として記録
5. **C. retrospective の保存場所変更 + 削除ポリシー導入** (workflow 構造変更): 各サイクルディレクトリに retrospective.md が散在すると「対応済みかどうか」が判別困難なため、`docs/adr/` 同様の集約構造 `docs/retrospective/<cycle-id>.md` に変更し、改善対応済み retrospective は削除する運用 (一時的な報告ボックス扱い) を導入する。本サイクルで対応済みの 3 件 (`2026-04-24-ai-dlc-plugin-bootstrap` / `2026-04-26-add-qa-design-step` / `2026-04-29-integrate-self-review-into-external`) は移動せず削除。本サイクル自身の retrospective は Step 9 で新パスに保存

ユーザー判断で対応見送りとなった項目は次のとおり (ADR には記録しない):

- **A-1 implementer / A-3 planner の 3 ルール / B 全項目**: 「当たり前 / 局所的すぎてスキルに加えるのは不適」「別 PR で対応中」「現状でも検出可能」のいずれか。ADR に残す価値もないため不要マーク
- **A-6 / A-7 deprecation 言い換えパターン**: 不要。直前サイクルで 1 件発生したのみで再現性が弱く、ADR に残す価値もない (CLI 化時に必要なら新規判断)

成功条件は「3 件の運用ルールが各 Specialist 本文に grep で検出できる、A-4 用 ADR ファイルが新規 1 件起票され保留事項が記録されている、retrospective が `docs/retrospective/` 集約構造へ移行し過去 3 件が削除され削除ポリシーが workflow 文書に明記されている、既存の skill-reviewer ルール違反を新たに発生させない」状態に到達すること。

## スコープ

ユーザー判断 (Step 1 ゲートでの個別評価) を経て、本サイクルは以下の **3 つの Specialist 本文修正 + 1 つの ADR 起票** に絞られた。各項目に「なぜ必要か」と「出典 retrospective」を併記する。

### A-2. dev-workflow/SKILL.md (Report-Based Confirmation セクションに 3-5 案推奨を追記)

`plugins/dev-workflow/skills/dev-workflow/SKILL.md` の **「Report-Based Confirmation for In-Progress Questions」セクション** (現状 L41-L52 付近) のレポート最小構成記述に追記:

- 既存の最小構成: `# 目的` / `# これまでの経緯` / `# 選択肢と根拠` / `# 推奨案` / `# 確認したい事項`
- 追記内容 (スキル本体に書く文言は実証引用なしで簡潔に): 「**選択肢と根拠は 3-5 案を推奨。** 2-3 案では選択肢を絞りすぎて事後修正が必要になりやすい」
  - **なぜ必要か (本 Intent Spec のみに記載、スキル本体には書かない)**: `2026-04-26-add-qa-design-step` サイクルで「5 トピック × 各 2-4 案」の代替案分析を実施したところ、後段でのユーザー指摘のような方針変更が発生しても影響範囲が局所的だった
  - **なぜ dev-workflow 1 箇所か**: `Report-Based Confirmation for In-Progress Questions` は計画段階 Specialist (intent-analyst / architect / qa-analyst / planner) 全てが共通参照する**質問プロトコル**であり、ここに集約することで Specialist 個別本文への重複追記を回避できる
  - **なぜスキル本体に出典引用を含めないか**: retrospective ファイル自体が C 項目で削除される上、スキル本体に過去サイクル番号のような実証引用を残すのはスキルのコンテキストを無駄に増やすだけ。出典は Intent Spec / commit message に残せば十分
  - **設計書の代替案と採用理由 (`shared-artifacts/references/design.md` L48 の「2-3 個」) は別概念 (設計書品質の要件) のため本サイクルでは触らない**
  - **出典 (Intent Spec のみ、スキル本体には書かない)**: `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md` L21, L72

### A-5. specialist-reviewer

`plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の本文「観点別のレビュー指針」セクションに `holistic` 小節を新設:

- **holistic 小節の内容**: 「design.md と実装の整合性チェックを Round 1 必須項目化」「Task Plan 完了判定」「Intent Spec 成功基準充足見込み」「明白な bug 早期検出」をチェックリスト化
  - **なぜ必要か**: research note `operational-rules-mapping.md` (本サイクル Step 2) で本文 L88-L122「観点別のレビュー指針」に security / performance / readability / test-quality / api-design の 5 観点のみ存在し、`holistic` 小節が完全欠落していることを発見。直前サイクルでは frontmatter description / Step 7 セクションの本文には holistic が反映されたが、本文の観点別小節への反映が漏れていた
  - **出典 (実装課題の根本原因)**: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md` L52 (T4 が design.md 約束を見落とした) / L90 (reviewer 改善案)
  - **出典 (現状の欠落の証拠)**: 本サイクル `research/operational-rules-mapping.md` R14

### A-8. specialist-retrospective-writer

`plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md` 本体に **再活性化が 1 回以上発生したタスクの SHA 列挙手順** を追加:

- 内容: 「retrospective.md 作成時、`TODO.md` の `re_activations >= 1` のタスクについて再活性化を引き起こした修正コミット SHA を列挙する」
  - **なぜ必要か**: 直前サイクル T2 chain bug → T3a 復元やり直し で `re_activations: 1` が記録されたが、retrospective.md にはこのカウンタの根拠 (どの commit で再活性化が発生したか) が散発的にしか記載されなかった。次サイクルで「同種事故が起きた commit を grep で発見する」フックがないため、Specialist 段階で SHA 列挙を標準化する
  - **出典**: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md` L27 (TODO.md re_activations 動作実証) / L70 (Blocker 化閾値の議論) / L91 (改善案)

### C. Retrospective の保存場所変更 + 削除ポリシー導入 (workflow 構造変更)

retrospective の運用方針を **「永続記録」から「一時的な報告ボックス」** に変更し、`docs/adr/` と同じパターンの集約ディレクトリに保存先を移す。

#### C-1. 保存場所の集約

- **新パス**: `docs/retrospective/<cycle-id>.md` (例: `docs/retrospective/2026-04-29-retro-cleanup.md`)
- **<cycle-id>**: サイクル ID (日時 + slug、`docs/dev-workflow/<id>/` で使う ID と完全同一)
- **新規ディレクトリ作成**: `docs/retrospective/` (gitkeep 等は不要、ファイル作成時に自動的に作られる)
- **ADR との対比**: `docs/adr/` は意思決定の永続記録 (`confirmed: true` にして不変)、`docs/retrospective/` は次サイクルでの改善検討材料となる**揮発性レポート**

#### C-2. 削除ポリシーの導入

- 改善対応 / 確認済みの retrospective は **削除** する運用を Specialist スキル / dev-workflow skill 本文に明記
- 削除タイミング: 後続サイクルが当該 retrospective の改善案項目を Intent Spec で検討し、対応 / 不要 / 保留 (ADR 化) のいずれかに判断した時点
- 削除されない retrospective: 直近 1〜2 サイクル分 (まだ改善検討対象になっていないもの)
- ADR との対比: 「永続記録すべき判断」は ADR に切り出し、retrospective 自体は削除して構わない

#### C-3. 影響を受けるスキル / ファイルの更新

- `plugins/dev-workflow/skills/dev-workflow/SKILL.md`:
  - Step 9 (Retrospective) セクションの保存先記述を `docs/dev-workflow/<id>/retrospective.md` → `docs/retrospective/<cycle-id>.md` に更新
  - 「成果物保存構造」ASCII から `retrospective.md` 行を削除 (集約ディレクトリへ移動したため)
  - 「サイクル外の成果物」相当のセクション (ADR と並列) に retrospective を追記
  - 削除ポリシーの記述追加
- `plugins/dev-workflow/skills/shared-artifacts/SKILL.md`:
  - 成果物一覧テーブルの retrospective 行で保存先パスを更新
  - 保存構造 ASCII から retrospective を除外 (集約ディレクトリ側に置く)
  - 「サイクル外の成果物」セクションに retrospective を追記 (ADR / In-Progress 一時レポートと並列)
- `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md`:
  - 「ファイル位置」記述を新パスに更新
  - 削除ポリシーを記載 (一時的な報告ボックス扱い)
- `plugins/dev-workflow/skills/shared-artifacts/templates/retrospective.md`:
  - ヘッダコメントの保存先注記を更新 (テンプレ自体の構造は維持)
- `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md`:
  - 出力先パスを新パスに更新 (A-8 の SHA 列挙ルール追記と同一コミットでまとめる)

#### C-4. 過去 retrospective ファイルの削除 (本サイクルで対応済み 3 件)

ユーザー判断で「移動不要、そのまま削除」:

- `docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md` を `git rm`
- `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md` を `git rm`
- `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md` を `git rm`

これら retrospective から導出した改善提案は本サイクルおよび直前サイクルですべて消化済み。残しておく価値がないためファイル自体を削除する (Git 履歴では参照可能なので情報は失われない)。

#### C-5. 本サイクル自身の retrospective (Step 9 で生成)

本サイクル `2026-04-29-retro-cleanup` の Step 9 で生成される retrospective は、**新パス** `docs/retrospective/2026-04-29-retro-cleanup.md` に保存する。`docs/dev-workflow/2026-04-29-retro-cleanup/` ディレクトリ内には `retrospective.md` を作らない。

なぜ必要か: ユーザー判断 (本対話)。「対応済みかどうかの判別が難しい」「一度対応すれば残す価値が薄い (修正サイクルの Intent Spec で十分)」という運用課題の解決。`docs/adr/` の集約構造が安定運用されていることから類推して同パターンを採用。

### ADR. A-4 (researcher のプロジェクト固有スキル棚卸し) の保留記録

`docs/adr/YYYY-MM-DD-researcher-project-skill-inventory-deferral.md` を新規起票し、A-4 を「対応せず」と判断した経緯と将来再検討の条件を記録する。他の見送り項目 (A-1 / A-3 / A-6 / A-7 / B) は ADR に残す価値がないと判断したため記録しない。

ADR 本文に retrospective ファイルパスは記載しない (C-4 で削除されるため)。代わりに**サイクルディレクトリ**を参照する。retrospective の中身は git 履歴に残る。

- **記録内容**:
  - **背景**: `2026-04-26-add-qa-design-step` サイクルで researcher の言語固有スキル調査観点が高品質だったことを踏まえた改善提案
  - **決定**: 本サイクルでは researcher 本文への明示追記を **対応しない**。Claude Code の自動ロード機構 (skill discovery) に期待し、サイクル開始時点で利用可能な言語固有スキルが Specialist 起動コンテキストに含まれることを前提とする
  - **影響**: researcher が言語固有スキルを能動的に棚卸しせず、自動ロードで暗黙に利用される構造を維持。サイクル間で Specialist が必要なスキルにアクセスできない事象が再発する可能性は残る
  - **再検討トリガー**:
    - Claude Code の skill discovery の挙動変更 (動的ロードが廃止される、トリガー精度が低下する等)
    - dev-workflow サイクル中に「言語固有スキルの取りこぼし」起因の Blocker / Major が発生
    - dev-workflow CLI 化で Specialist 起動コンテキストを明示制御する設計が固まったとき
  - **関連サイクル**: `docs/dev-workflow/2026-04-26-add-qa-design-step/` (サイクルディレクトリ全体、retrospective.md は本サイクル C-4 で削除済み — git 履歴から参照可)
- **なぜ ADR にするか**: 「自動ロードに期待」という判断は将来の Claude Code 仕様変更で前提が崩れる可能性があり、その時点で再判断するための根拠を残す必要があるため

### スコープ運用

- 影響範囲は `plugins/dev-workflow/` 配下、`docs/adr/` の新規 ADR ファイル 1 件、`docs/retrospective/` の新規ディレクトリ + 1 ファイル (本サイクルの retrospective)、過去 3 サイクルの retrospective 削除のみ
- 過去サイクル成果物 (`docs/dev-workflow/2026-04-*/`) のうち retrospective.md 以外は遡及修正禁止 (完了済み履歴として保持)。retrospective.md は C-4 で 3 件削除
- 各 Specialist 本文への追記は既存 SKILL.md の構造を維持し、新規セクションを作る場合でも 30 行以内に収める
- `references/` の新規ディレクトリは作成しない

## 非スコープ

### 既に解消済み（直前サイクル等で対応済み）

- 過去サイクル成果物 `docs/dev-workflow/2026-04-*/` の遡及修正
- 旧 `main-{inception,construction,verification}` 3 スキル（フラット化で削除済み）
- `ai-dlc` キーワード衝突（dev-workflow 改名で解消済み）
- Self-Review 削除関連（直前サイクルで完了済み）
- 深刻度ラベル統一（直前サイクルで完了済み）

### skill-reviewer ルール違反でないため対応不要

- `dev-workflow/SKILL.md` および他 SKILL.md の行数 / 語数圧縮（G3 / G7 違反なし）
- specialist-* description 圧縮（G2 #5 の 1024 文字以内に全件収まっており、Do NOT use for を本文に移すと負のトリガー機能を失うため逆効果）
- `references/` 新規ディレクトリ作成

### 本サイクルで「対応せず」と判断 (ADR に残す価値なし、不要マーク)

- **A-1 implementer (gsed 2-phase placeholder / git revert ルール)**: 「当たり前 / 局所的すぎてスキルに加えるのは不適」とユーザー判断。ADR にも残さない
- **A-3 planner の 3 ルール**: (1) 全 reference スキャン、(3) design.md 章節紐付けは A-1 と同じく局所的すぎる、(2) サブタスク分解は別 PR で対応中。ADR にも残さない
- **A-6 / A-7 validator / intent-analyst の deprecation 言い換えパターン**: **不要**。直前サイクルで 1 件発生したのみで再現性が弱く ADR に残す価値もない (CLI 化時に必要なら新規判断)
- **B 全項目 (shared-artifacts/references/* 追記)**: progress-yaml は CLI で対応予定、他は A-1 / A-3 と同じ理由で局所的、または現状で検出可能。ADR にも残さない

### 本サイクルで「対応せず」と判断、ADR で記録 (将来再検討の根拠を残す)

- **A-4 researcher のプロジェクト固有スキル棚卸し**: 自動ロードに期待、将来再検討。詳細は「ADR. A-4 の保留記録」セクション参照

### その他の非スコープ

- 新規 Specialist の追加（既存 9 体を維持）
- `dev-workflow` プラグインの実行可能コード化（Markdown のみ）
- 観点別 reviewer の並列度上限の変更
- ステップ削除・追加に伴うフェーズ概念の再導入（フラット 9-step リストを維持）
- baseline commit の design.md 記録ルール追加（本来は `git revert` を第一選択にすれば不要。実装ルールとしてはユーザー判断で削除）

## 成功基準

ファイル削除・更新の達成度を観測可能な形で計測する。`<root> = plugins/dev-workflow/`、コマンドは monorepo ルートから実行する前提。`gwc -l` / `ggrep` を使用する。

### A. 本文への運用ルール追記の検証

1. `ggrep -nE '3-5|3〜5|3 から 5|3.{0,3}案.{0,3}5' plugins/dev-workflow/skills/dev-workflow/SKILL.md` の結果が **1 件以上**、かつ `Report-Based Confirmation` セクション内 (L41-L52 付近) であること（A-2: 3-5 案推奨が Report-Based Confirmation セクションに追記されている）
2. `ggrep -nE '#### holistic|^#### *holistic' plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の結果が **1 件以上**、または「観点別のレビュー指針」セクション内に `holistic` を独立小節として持つ（A-5: holistic 小節が本文に新設されている）
3. `ggrep -nE 'design\.md と実装|design\.md.*整合|整合性チェック' plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の結果が **1 件以上**（A-5: holistic 観点に design.md ↔ 実装整合性チェックが記載されている）
4. `ggrep -nE 're_activations|再活性化.*SHA|SHA.*列挙' plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md` の結果が **1 件以上**（A-8: 再活性化タスクの SHA 列挙手順が本文に追記されている）

### B. ADR の起票 (A-4 のみ)

5. `docs/adr/` 配下に **新規 ADR ファイルが 1 件追加** されている（内容が A-4 関連であれば名前の細部は不問）
6. 新 ADR に **A-4 の決定 / 影響 / 再検討トリガー / 関連サイクル参照** が記録されている（`Decision` / `Impact` / `再検討トリガー` / `2026-04-26-add-qa-design-step` の各キーワードが本文に存在。retrospective.md ファイル自体は C-4 で削除されるため参照は cycle ディレクトリのみとする）
7. 新 ADR の frontmatter `confirmed: false`（adr スキル準拠、初期はレビュー前ステータス）

### C. retrospective 保存場所変更 + 削除ポリシー (workflow 構造変更)

8. `test ! -f docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md` が真 (削除完了)
9. `test ! -f docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md` が真
10. `test ! -f docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md` が真
11. `test -d docs/retrospective` が真 (Step 9 で本サイクル分の retrospective ファイル作成時に自動生成、または明示的に作成)
12. **Step 9 完了後**: `test -f docs/retrospective/2026-04-29-retro-cleanup.md` が真 (本サイクル自身の retrospective が新パスに保存されている)
13. `ggrep -nF 'docs/retrospective/' plugins/dev-workflow/skills/dev-workflow/SKILL.md plugins/dev-workflow/skills/shared-artifacts/SKILL.md plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md` の結果が **各 1 件以上**（保存先記述が新パスに更新されている）
14. `ggrep -nE '削除|揮発|報告ボックス|temporary' plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md plugins/dev-workflow/skills/dev-workflow/SKILL.md` の結果が **1 件以上**（削除ポリシーが reference または skill 本文に記載されている）

### D. 既存機能の維持 (skill-reviewer ルール非違反の維持)

15. `gwc -w plugins/dev-workflow/skills/dev-workflow/SKILL.md` の結果が **5,000 語以下**（skill-reviewer G3 / G7 違反を新たに発生させない、現状 3,733 語）
16. `gwc -w plugins/dev-workflow/skills/specialist-*/SKILL.md` 各ファイルが **5,000 語以下**
17. `gwc -l plugins/dev-workflow/skills/specialist-*/SKILL.md` で本サイクルが触る 3 specialist の本体行数が **既存比 +30% 以内** に収まる（追記による肥大化を抑制、現状 architect 100 行 / reviewer 139 行 / retrospective-writer 99 行）
18. **3 specialist の description が skill-reviewer G2 #5 の上限 1024 文字以内を維持**
19. 既存 ADR `docs/adr/2026-04-26-dev-workflow-rename-and-flatten.md` のフラット構造方針に違反しない
20. 既存の grep ベース成功基準パターン (`grep -rnE -i 'self[-_]review|Self-Review' plugins/dev-workflow/` が 0 件等) を破壊しない

## 制約

### 技術的制約

- 全ファイルは Markdown / JSON / YAML のみ（実行コード非該当）
- macOS 環境のため `gsed` / `ggrep` / `gwc` を使用（`macos-cli-rules` スキル準拠）
- 大規模機械置換が発生する場合は **gsed `-e` 連鎖を禁止** し、2-phase placeholder で実施する（直前サイクル T2 chain bug の教訓を本サイクルでも適用）
- 各 Specialist 本文への追記は既存セクション末尾に追加するか、独立した小節 (≤ 30 行) として配置する。既存内容を破壊しない
- 本サイクルは新規ディレクトリ作成・行数圧縮・description 圧縮を行わない（skill-reviewer ルールに違反していないため）

### 規範的制約

- `dev-workflow` の基本方針（Main-Centric Orchestration / One-Shot Specialist / Gate-Based Progression / Artifact-Driven Handoff / Project-Rule Precedence）は全継承
- 既存 ADR `docs/adr/2026-04-26-dev-workflow-rename-and-flatten.md` のフラット構造（フェーズ概念非導入）を維持
- 過去サイクル成果物 (`docs/dev-workflow/2026-04-*/`) の遡及修正禁止
- monorepo 共通の memory rules: `gsed` 使用 / `2>&1` 不使用 / `vp run` 経由 / `as` 型アサーション禁止 (TS の場合) / git commit は sandbox 外実行 / `npx` 禁止
- ドキュメント言語: 既存スキル本文の日本語踏襲、frontmatter / template / agent description は英語または既存踏襲

### 組織的制約

- 作業者は totto2727（Main 兼 設計者）。本サイクルは単独実行
- レビュー単位は各ステップ完了時の Artifact-as-Gate-Review（auto モード進行）
- 期限なし（ユーザーの判断ペースに合わせる）
- baseline commit: `4f9e7dd docs(dev-workflow/2026-04-29-retro-cleanup): initialize cycle`（直前サイクル完了 commit `fd0f930` の直後）

## 関連リンク

- 直前サイクル retrospective: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md`
- bootstrap retrospective: `docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md`
- add-qa-design-step retrospective: `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md`
- 既存 ADR: `docs/adr/2026-04-26-dev-workflow-rename-and-flatten.md`
- 直前サイクル Intent Spec（番号シフト先例）: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/intent-spec.md`
- 既存スキル: `plugins/dev-workflow/skills/dev-workflow/SKILL.md`, `plugins/dev-workflow/skills/specialist-common/SKILL.md`, `plugins/dev-workflow/skills/specialist-*/SKILL.md` 全 9 体
- 既存 shared-artifacts: `plugins/dev-workflow/skills/shared-artifacts/SKILL.md` および `templates/`, `references/` 全般

## 未解決事項

(主要意思決定はユーザー要求 + intent-analyst による auto モード判断で確定済み。以下は Step 2 Research / Step 3 Design / Step 4 QA Design で確認・決定する細部)

- **本文追記の重複回避方針**: gsed 2-phase placeholder ルールを specialist-implementer 本体と shared-artifacts/references/implementation-log.md の両方に書くと、bootstrap retrospective M#3 と同じ「真のソース重複」アンチパターンを再現するリスクあり。Step 3 で「真のソースは specialist-implementer 本体、reference は 1 行参照のみ」のような原則を確定
- **specialist-retrospective-writer 本体への追記 vs template 直接追加**: 「再活性化が 1 回以上発生したタスクの SHA 列挙」欄を retrospective.md template に追加するかどうかは Step 3 で決定
- **specialist-reviewer 本文の holistic 追記の現状確認**: 直前サイクルで holistic 観点の責務追加は実施済みのため、research note `operational-rules-mapping.md` で「観点別のレビュー指針」セクションに holistic 小節が完全欠落していることを確認済み。Step 3 で本文への小節新設方針を確定
- **task-plan の Wave 構造**: 本サイクルは A (specialist 本文追記) と B (shared-artifacts/references 追記) の 2 軸に絞られたため、Step 5 で並列 Wave 化を検討
- **gsed 機械置換の有無**: 本サイクルは新規追記が中心で、機械置換は基本不要。仮に発生する場合は 2-phase placeholder を必須とする
