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

そのため本サイクルは **構造的圧縮 (行数 / description) を含めず**、過去 retrospective で明文化された運用ルール追記のみに絞る:

1. **本文への運用ルール追記**: gsed 2-phase placeholder / メタサイクル baseline 特定 / design.md ↔ template/reference 紐付け / 影響範囲スキャン / 代替案 3-5 案推奨 / progress.yaml 編集ルールなど、過去 retrospective で明文化されたベストプラクティスを各 Specialist の本文・各 reference に追記する
2. **specialist-reviewer の holistic 観点小節新設**: research で発見した未反映項目 (本文「観点別のレビュー指針」セクションに holistic 小節が完全欠落) を補完

成功条件は「retrospective 由来の運用ルールが grep で検出できる、specialist-reviewer 本文に holistic 小節が存在する、既存の skill-reviewer ルール違反を新たに発生させない」状態に到達すること。

## スコープ

### A. 本文への運用ルール追記 (Specialist 改善)

過去 retrospective で明文化された運用ルールを、各 Specialist 本体・各 reference に追記する:

#### A-1. specialist-implementer

- `plugins/dev-workflow/skills/specialist-implementer/SKILL.md` の失敗モード表または手順節に「**gsed `-e` 連鎖は禁止、必ず 2-phase placeholder で機械置換する**」ルールを追加
- 例: `old → __SRK_NEW<n>__` を別 sed 呼び出し、`__SRK_NEW<n>__ → new` で復元、実行前後に `ggrep -F __SRK_ <root>` で 0 件確認

#### A-2. specialist-architect

- `plugins/dev-workflow/skills/specialist-architect/SKILL.md` 本体に「**メタサイクル時の baseline commit を design.md に明示記録する**」手順を追加
- design.md テンプレート（`shared-artifacts/templates/design.md`）に baseline commit 記録欄を追加するかどうかは Step 3 Design で決定（任意）
- 「**代替案分析は 3-5 案を推奨**」（現行 2-3 案 → 3-5 案）に更新（add-qa-design-step retrospective より）

#### A-3. specialist-planner

- `plugins/dev-workflow/skills/specialist-planner/SKILL.md` 本体に以下 3 点を追加:
  1. **task-plan 作成時に `shared-artifacts/references/*` 全件をスキャンして影響範囲を確認する** ルール
  2. **大規模修正タスクは複数サブタスクに分解** することを推奨（例: `dev-workflow/SKILL.md` 全面書き換えの場合、ステップテーブル / 全体図 / 詳細セクション / コミット規約 / 並列ガイド / ロールバック表 を別 subtask に分割）
  3. **design.md の章節 ↔ template/reference を紐付ける記法**（例: 各タスクの「設計参照」欄に design.md の対応セクション L 範囲を明記し、影響範囲が `templates/` / `references/` に及ぶ場合はファイル名を列挙）

#### A-4. specialist-researcher

- `plugins/dev-workflow/skills/specialist-researcher/SKILL.md` 本体に「**該当言語のプロジェクト固有スキル棚卸し**」観点をデフォルト調査項目化（add-qa-design-step retrospective より）
- 「**メタサイクル時は前サイクルの 'all-files-in-target-state' commit を baseline として特定する**」観点を追加（integrate-self-review retrospective より）

#### A-5. specialist-reviewer

- `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の `holistic` 観点責務に「**design.md と実装の整合性チェックを Round 1 必須項目化**」を追記（integrate-self-review retrospective より）
- ただし、本サイクルは `holistic` の責務追記が中心で、Round 1 必須項目化の文言は既に直前サイクルで一部反映されている可能性があるため、grep して未反映分のみを追記

#### A-6. specialist-validator

- `plugins/dev-workflow/skills/specialist-validator/SKILL.md` または `shared-artifacts/references/validation-report.md` に「**deprecated フィールドの言い換えで grep 検証を通すケースを観測可能 + 文書化された例外として記録するパターン**」を追記（integrate-self-review retrospective より）

#### A-7. specialist-intent-analyst

- `plugins/dev-workflow/skills/specialist-intent-analyst/SKILL.md` 本体に「**メタサイクルで成功基準が言い換えで grep 検出を逃れるグレーゾーンを許容する場合、その許容範囲を Intent Spec の成功基準セクション内に明記する**」手順を追加（integrate-self-review retrospective より）

#### A-8. specialist-retrospective-writer

- `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md` 本体に「**再活性化が 1 回以上発生したタスクの SHA 列挙**」欄の retrospective.md template への追加を促す手順を追記
- ただし template 自体への追加は本サイクルで実施するか Step 3 Design で決定する

### B. shared-artifacts/references/* への運用ルール追記

- `shared-artifacts/references/progress-yaml.md` に「**新フィールド追加時は既存 null フィールドを置き換える（削除 → 追加ではなく上書き）**」運用ルールを明記（add-qa-design-step retrospective より）
- `shared-artifacts/references/task-plan.md` に「**全 reference スキャンルール**」「**大規模修正タスクのサブタスク分解推奨**」を追記
- `shared-artifacts/references/implementation-log.md` または該当箇所に「**gsed 2-phase placeholder ベストプラクティス**」を簡潔に記述（specialist-implementer 本体との重複を避け、この reference では具体例のみ）
- `shared-artifacts/references/design.md` に「**代替案 3-5 案推奨**」「**design.md 章節 ↔ template/reference 紐付け表記法**」を追記

### スコープ運用

- 影響範囲は `plugins/dev-workflow/` 配下のみ
- 過去サイクル成果物 (`docs/dev-workflow/2026-04-*/`) は遡及修正禁止（完了済み履歴として保持）
- 各 Specialist 本文への運用ルール追記は既存 SKILL.md の構造を維持し、新規セクションを作る場合でも 30 行以内に収める
- `references/` の新規ディレクトリは作成しない（既存の `shared-artifacts/references/*` への追記のみ）

## 非スコープ

- **過去サイクル成果物 `docs/dev-workflow/2026-04-*/` の遡及修正**
- **既に廃止済み旧 `main-{inception,construction,verification}` 3 スキル**（実体が存在しないため）
- **既に解消済み `ai-dlc` キーワード衝突**（dev-workflow 改名で解消済み）
- **既に解消済み Self-Review 削除関連**（直前サイクルで完了済み）
- **既に解消済み深刻度ラベル統一**（直前サイクルで完了済み）
- **新規 Specialist の追加**（既存 9 体を維持）
- **`dev-workflow` プラグインの実行可能コード化**（Markdown のみ）
- **マーケットプレイス公開の方針決定**
- **観点別 reviewer の並列度上限の変更**
- **ステップ削除・追加に伴うフェーズ概念の再導入**（フラット 9-step リストを維持）
- **新規 ADR の起票**（本変更は dev-workflow プラグイン内のスキル責務再配置であり横断的決定ではないため、必要なら design.md で記録）
- **「次回サイクルで実機能ドッグフード時に検証」項目**（intent-analyst の validator 事前相談・implementer の context window 予算見積りなど、実機能サイクルでなければ検証できない提案は本サイクル非対象）
- **保存構造 ASCII 図の真のソース化作業**（既に dev-workflow 側 L621-L622 で参照リンク化されており、再確認のみで実質作業なし）
- **specialist-common 以外のスキルへの description ガード**（specialist-common は本サイクル外から呼ばれない構造のため description 制約は緩い）
- **`dev-workflow/SKILL.md` および他 SKILL.md の行数 / 語数圧縮**（skill-reviewer G3 / G7 違反なしのため）
- **specialist-* description の圧縮**（skill-reviewer G2 #5 の 1024 文字以内に全件収まっており、Do NOT use for を本文に移すと負のトリガー機能を失うため逆効果）
- **`references/` 新規ディレクトリ作成**（`dev-workflow/references/` / `specialist-common/references/` のいずれも skill-reviewer 違反でないため作成不要）

## 成功基準

ファイル削除・更新の達成度を観測可能な形で計測する。`<root> = plugins/dev-workflow/`、コマンドは monorepo ルートから実行する前提。`gwc -l` / `ggrep` を使用する。

### A. 本文への運用ルール追記の検証 (grep でキーワード検出)

1. `ggrep -nE '2-phase|placeholder|__SRK_' plugins/dev-workflow/skills/specialist-implementer/SKILL.md` の結果が **1 件以上**（gsed 2-phase placeholder ルールが本文に追記されている）
2. `ggrep -nE 'baseline|all-files-in-target-state' plugins/dev-workflow/skills/specialist-architect/SKILL.md plugins/dev-workflow/skills/specialist-researcher/SKILL.md` の結果が **2 件以上**（メタサイクル baseline 特定手順が architect / researcher 本文に追記されている）
3. `ggrep -nE '3-5|3〜5|3 から 5|3.{0,3}案.{0,3}5' plugins/dev-workflow/skills/specialist-architect/SKILL.md plugins/dev-workflow/skills/shared-artifacts/references/design.md` の結果が **1 件以上**（代替案 3-5 案推奨が architect 本文または design reference に記載されている）
4. `ggrep -nF 'shared-artifacts/references/' plugins/dev-workflow/skills/specialist-planner/SKILL.md` の結果が **1 件以上**（planner 本文に全 reference スキャンルールが記載されている）
5. `ggrep -nE 'サブタスク|サブ.?タスク|sub.?task' plugins/dev-workflow/skills/specialist-planner/SKILL.md` の結果が **1 件以上**（planner 本文に大規模修正タスクのサブタスク分解推奨が記載されている）
6. `ggrep -nE '章節|セクション.{0,5}紐付|template.*reference|references.*templates' plugins/dev-workflow/skills/specialist-planner/SKILL.md` の結果が **1 件以上**（design.md 章節 ↔ template/reference 紐付け表記法が記載されている）
7. `ggrep -nE 'プロジェクト固有スキル|言語スキル|プロジェクト.?固有' plugins/dev-workflow/skills/specialist-researcher/SKILL.md` の結果が **1 件以上**（researcher 本文に言語/プロジェクト固有スキル棚卸し観点が記載されている）
8. `ggrep -nE 'design\.md と実装|design\.md.*整合|整合性チェック' plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の結果が **1 件以上**（holistic 観点に design.md ↔ 実装整合性チェックが記載されている）
9. `ggrep -nE 'deprecated|言い換え|文書化.*例外' plugins/dev-workflow/skills/specialist-validator/SKILL.md plugins/dev-workflow/skills/shared-artifacts/references/validation-report.md` の結果が **1 件以上**（validator または validation-report reference に deprecated 言い換えパターンが記載されている）
10. `ggrep -nE '上書き|null フィールド|既存 null|新フィールド' plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md` の結果が **1 件以上**（progress-yaml reference に新フィールド追加時の上書きルールが記載されている）

### B. specialist-reviewer の holistic 小節新設

11. `ggrep -nE '#### holistic|^#### *holistic' plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の結果が **1 件以上**、または「観点別のレビュー指針」セクション内に `holistic` を独立小節として持つ（research note `operational-rules-mapping.md` で本文に小節が完全欠落と確認済み）

### C. 既存機能の維持 (skill-reviewer ルール非違反の維持)

12. `gwc -w plugins/dev-workflow/skills/dev-workflow/SKILL.md` の結果が **5,000 語以下**（skill-reviewer G3 / G7 違反を新たに発生させない、現状 3,733 語）
13. `gwc -w plugins/dev-workflow/skills/specialist-*/SKILL.md` 各ファイルが **5,000 語以下**
14. `gwc -l plugins/dev-workflow/skills/specialist-*/SKILL.md` で各 specialist 本体行数が **既存比 +30% 以内** に収まる（追記による肥大化を抑制）
15. **全 specialist description が skill-reviewer G2 #5 の上限 1024 文字以内を維持**（追記により description を伸ばさないことを確認）
16. 既存 ADR `docs/adr/2026-04-26-dev-workflow-rename-and-flatten.md` のフラット構造方針に違反しない
17. 既存の grep ベース成功基準パターン (`grep -rnE -i 'self[-_]review|Self-Review' plugins/dev-workflow/` が 0 件等) を破壊しない（直前サイクルの達成状態を維持）

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
