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
- `main-workflow/SKILL.md`（既に `dev-workflow/SKILL.md` にリネーム済み、ただし 820 行で旧 M#1 と同質の課題が再発しており本サイクルで圧縮対象）

本サイクルは `dev-workflow` プラグインの**自己改修**（meta-reflexive 開発）であり、変更対象は Markdown のみ。実行可能コードを含まない。

## 目的

3 つの retrospective に蓄積した残提案を **「3 つの軸」** で段階的に反映し、`dev-workflow` プラグインを次の実機能サイクルに耐える形にチューニングする:

1. **行数圧縮 / 重複削除（構造）**: `dev-workflow/SKILL.md` (820 行) と `specialist-common/SKILL.md` (228 行) を `references/` 切り出しで実質本体を縮小し、Main / Specialist の文脈窓予算を改善する
2. **description 圧縮（API 表面）**: 各 `specialist-*/SKILL.md` の description (現状 700-1300 文字) を 700 文字以下に揃え、トリガー条件と Do NOT を明確化する
3. **本文への運用ルール追記（中身）**: gsed 2-phase placeholder / メタサイクル baseline 特定 / design.md ↔ template/reference 紐付け / 影響範囲スキャン / 代替案 3-5 案推奨 / progress.yaml 編集ルールなど、過去 retrospective で明文化されたベストプラクティスを各 Specialist の本文・各 reference に追記する

成功条件は「`dev-workflow/SKILL.md` 行数が 500 行以下、`specialist-common/SKILL.md` が 180 行以下、各 specialist description が 700 文字以下、retrospective 由来の運用ルールが grep で検出できる」状態に到達すること。

## スコープ

### A. 構造的圧縮 (references 切り出し)

- `plugins/dev-workflow/skills/dev-workflow/references/` を新規作成し、以下を切り出す:
  - `commit-policy.md` (現 SKILL.md L684-L750「ステップ完了時のコミット規約」セクション ≈ 67 行)
  - `project-rule-integration.md` (現 SKILL.md L633-L682「プロジェクト固有ルールとの関係」セクション ≈ 50 行)
  - `coordination-protocol.md` (現 SKILL.md L545-L612「調整プロトコル (Main ↔ Specialist)」セクション ≈ 67 行) — 必要に応じて
  - `rollback-recovery.md` (現 SKILL.md L770-L810「逸脱時のリカバリ」セクション ≈ 40 行) — 必要に応じて
  - 本体は各セクションを 2-3 行のサマリ + 「詳細は `references/<name>.md` 参照」リンクに置換
- `plugins/dev-workflow/skills/specialist-common/references/` を新規作成し、以下を切り出す:
  - `scope-discipline.md` (現 SKILL.md L148-L165 「5. スコープ規律」 ≈ 18 行)
  - `git-guardrails.md` (現 SKILL.md L178-L195 「7. Git コミットに関する注意」+「Git ガードレール」 ≈ 17 行)
  - `imperative-style.md` (現 SKILL.md L221-L228 「10. 命令形・具体性の原則」 ≈ 8 行)
  - 本体はライフサイクル / 入出力契約 / 失敗プロトコル / プロジェクト固有ルール優先に絞る
- `plugins/dev-workflow/skills/shared-artifacts/SKILL.md` と `dev-workflow/SKILL.md` の保存構造 ASCII 図重複は **既に dev-workflow 側 L621-L622 で `shared-artifacts` への参照に置換済み** だが、再度 grep で重複が残っていないか確認のうえ、残存する場合のみ削除（削除作業より確認作業がメイン）

### B. description 圧縮 (frontmatter)

各 `specialist-*/SKILL.md` の description を YAML スカラ値として 700 文字以下に圧縮する（現状 700-1300 文字）。圧縮方針:

- 「起動トリガー」「Do NOT use for」を本文「このスキルが扱わないこと」相当のセクションに移し、frontmatter は要約のみに
- ただし Claude Code の trigger condition 仕様上、description の主要キーワードは保持する
- 対象: `specialist-architect` (現 733) / `specialist-implementer` (現 767) / `specialist-intent-analyst` (現 897) / `specialist-planner` (現 1150) / `specialist-qa-analyst` (現 1093) / `specialist-researcher` (現 740) / `specialist-retrospective-writer` (現 1018) / `specialist-reviewer` (現 1297) / `specialist-validator` (現 709)
- `specialist-common` (現 1276) は Specialist 以外から起動されない設計上、現状でも問題ないが、可能なら 800 文字以下に圧縮

### C. 本文への運用ルール追記 (Specialist 改善)

過去 retrospective で明文化された運用ルールを、各 Specialist 本体・各 reference に追記する:

#### C-1. specialist-implementer

- `plugins/dev-workflow/skills/specialist-implementer/SKILL.md` の失敗モード表または手順節に「**gsed `-e` 連鎖は禁止、必ず 2-phase placeholder で機械置換する**」ルールを追加
- 例: `old → __SRK_NEW<n>__` を別 sed 呼び出し、`__SRK_NEW<n>__ → new` で復元、実行前後に `ggrep -F __SRK_ <root>` で 0 件確認

#### C-2. specialist-architect

- `plugins/dev-workflow/skills/specialist-architect/SKILL.md` 本体に「**メタサイクル時の baseline commit を design.md に明示記録する**」手順を追加
- design.md テンプレート（`shared-artifacts/templates/design.md`）に baseline commit 記録欄を追加するかどうかは Step 3 Design で決定（任意）
- 「**代替案分析は 3-5 案を推奨**」（現行 2-3 案 → 3-5 案）に更新（add-qa-design-step retrospective より）

#### C-3. specialist-planner

- `plugins/dev-workflow/skills/specialist-planner/SKILL.md` 本体に以下 3 点を追加:
  1. **task-plan 作成時に `shared-artifacts/references/*` 全件をスキャンして影響範囲を確認する** ルール
  2. **大規模修正タスクは複数サブタスクに分解** することを推奨（例: `dev-workflow/SKILL.md` 全面書き換えの場合、ステップテーブル / 全体図 / 詳細セクション / コミット規約 / 並列ガイド / ロールバック表 を別 subtask に分割）
  3. **design.md の章節 ↔ template/reference を紐付ける記法**（例: 各タスクの「設計参照」欄に design.md の対応セクション L 範囲を明記し、影響範囲が `templates/` / `references/` に及ぶ場合はファイル名を列挙）

#### C-4. specialist-researcher

- `plugins/dev-workflow/skills/specialist-researcher/SKILL.md` 本体に「**該当言語のプロジェクト固有スキル棚卸し**」観点をデフォルト調査項目化（add-qa-design-step retrospective より）
- 「**メタサイクル時は前サイクルの 'all-files-in-target-state' commit を baseline として特定する**」観点を追加（integrate-self-review retrospective より）

#### C-5. specialist-reviewer

- `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の `holistic` 観点責務に「**design.md と実装の整合性チェックを Round 1 必須項目化**」を追記（integrate-self-review retrospective より）
- ただし、本サイクルは `holistic` の責務追記が中心で、Round 1 必須項目化の文言は既に直前サイクルで一部反映されている可能性があるため、grep して未反映分のみを追記

#### C-6. specialist-validator

- `plugins/dev-workflow/skills/specialist-validator/SKILL.md` または `shared-artifacts/references/validation-report.md` に「**deprecated フィールドの言い換えで grep 検証を通すケースを観測可能 + 文書化された例外として記録するパターン**」を追記（integrate-self-review retrospective より）

#### C-7. specialist-intent-analyst

- `plugins/dev-workflow/skills/specialist-intent-analyst/SKILL.md` 本体に「**メタサイクルで成功基準が言い換えで grep 検出を逃れるグレーゾーンを許容する場合、その許容範囲を Intent Spec の成功基準セクション内に明記する**」手順を追加（integrate-self-review retrospective より）

#### C-8. specialist-retrospective-writer

- `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md` 本体に「**再活性化が 1 回以上発生したタスクの SHA 列挙**」欄の retrospective.md template への追加を促す手順を追記
- ただし template 自体への追加は本サイクルで実施するか Step 3 Design で決定する

### D. shared-artifacts/references/* への運用ルール追記

- `shared-artifacts/references/progress-yaml.md` に「**新フィールド追加時は既存 null フィールドを置き換える（削除 → 追加ではなく上書き）**」運用ルールを明記（add-qa-design-step retrospective より）
- `shared-artifacts/references/task-plan.md` に「**全 reference スキャンルール**」「**大規模修正タスクのサブタスク分解推奨**」を追記
- `shared-artifacts/references/implementation-log.md` または該当箇所に「**gsed 2-phase placeholder ベストプラクティス**」を簡潔に記述（specialist-implementer 本体との重複を避け、この reference では具体例のみ）
- `shared-artifacts/references/design.md` に「**代替案 3-5 案推奨**」「**design.md 章節 ↔ template/reference 紐付け表記法**」を追記

### スコープ運用

- 影響範囲は `plugins/dev-workflow/` 配下のみ
- 過去サイクル成果物 (`docs/dev-workflow/2026-04-*/`) は遡及修正禁止（完了済み履歴として保持）
- `references/` 新規ディレクトリの作成は `dev-workflow` と `specialist-common` の 2 箇所のみ。それ以外の specialist-* は既に description 圧縮 + 本文追記で完結

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

## 成功基準

ファイル削除・更新の達成度を観測可能な形で計測する。`<root> = plugins/dev-workflow/`、コマンドは monorepo ルートから実行する前提。`gwc -l` / `ggrep` を使用する。

### A. 行数圧縮

1. `gwc -l plugins/dev-workflow/skills/dev-workflow/SKILL.md` の結果が **500 行以下**（現状 820 行）
2. `gwc -l plugins/dev-workflow/skills/specialist-common/SKILL.md` の結果が **180 行以下**（現状 228 行）
3. `test -d plugins/dev-workflow/skills/dev-workflow/references` が真（references ディレクトリ新規作成）
4. `test -d plugins/dev-workflow/skills/specialist-common/references` が真
5. `plugins/dev-workflow/skills/dev-workflow/references/` 配下に **2 ファイル以上** 存在（最低 `commit-policy.md` と `project-rule-integration.md`）
6. `plugins/dev-workflow/skills/specialist-common/references/` 配下に **2 ファイル以上** 存在（最低 `scope-discipline.md` と `git-guardrails.md`）

### B. description 圧縮

7. `plugins/dev-workflow/skills/specialist-architect/SKILL.md` の description 文字数が **700 文字以下**（現状 733）
8. `plugins/dev-workflow/skills/specialist-implementer/SKILL.md` の description 文字数が **700 文字以下**（現状 767）
9. `plugins/dev-workflow/skills/specialist-intent-analyst/SKILL.md` の description 文字数が **700 文字以下**（現状 897）
10. `plugins/dev-workflow/skills/specialist-planner/SKILL.md` の description 文字数が **700 文字以下**（現状 1150）
11. `plugins/dev-workflow/skills/specialist-qa-analyst/SKILL.md` の description 文字数が **700 文字以下**（現状 1093）
12. `plugins/dev-workflow/skills/specialist-researcher/SKILL.md` の description 文字数が **700 文字以下**（現状 740）
13. `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md` の description 文字数が **700 文字以下**（現状 1018）
14. `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の description 文字数が **700 文字以下**（現状 1297）
15. `plugins/dev-workflow/skills/specialist-validator/SKILL.md` の description 文字数が **700 文字以下**（現状 709）

### C. 本文への運用ルール追記の検証 (grep でキーワード検出)

16. `ggrep -nE '2-phase|placeholder|__SRK_' plugins/dev-workflow/skills/specialist-implementer/SKILL.md` の結果が **1 件以上**（gsed 2-phase placeholder ルールが本文に追記されている）
17. `ggrep -nE 'baseline|all-files-in-target-state' plugins/dev-workflow/skills/specialist-architect/SKILL.md plugins/dev-workflow/skills/specialist-researcher/SKILL.md` の結果が **2 件以上**（メタサイクル baseline 特定手順が architect / researcher 本文に追記されている）
18. `ggrep -nE '3-5|3〜5|3 から 5|3.{0,3}案.{0,3}5' plugins/dev-workflow/skills/specialist-architect/SKILL.md plugins/dev-workflow/skills/shared-artifacts/references/design.md` の結果が **1 件以上**（代替案 3-5 案推奨が architect 本文または design reference に記載されている）
19. `ggrep -nF 'shared-artifacts/references/' plugins/dev-workflow/skills/specialist-planner/SKILL.md` の結果が **1 件以上**（planner 本文に全 reference スキャンルールが記載されている）
20. `ggrep -nE 'サブタスク|サブ.?タスク|sub.?task|分解' plugins/dev-workflow/skills/specialist-planner/SKILL.md` の結果が **1 件以上**（planner 本文に大規模修正タスクのサブタスク分解推奨が記載されている）
21. `ggrep -nE '章節|セクション.{0,5}紐付|template.*reference|references.*templates' plugins/dev-workflow/skills/specialist-planner/SKILL.md` の結果が **1 件以上**（design.md 章節 ↔ template/reference 紐付け表記法が記載されている）
22. `ggrep -nE 'プロジェクト固有スキル|言語スキル|プロジェクト.?固有' plugins/dev-workflow/skills/specialist-researcher/SKILL.md` の結果が **1 件以上**（researcher 本文に言語/プロジェクト固有スキル棚卸し観点が記載されている）
23. `ggrep -nE 'design\.md と実装|design\.md.*整合|整合性チェック' plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` の結果が **1 件以上**（holistic 観点に design.md ↔ 実装整合性チェックが記載されている）
24. `ggrep -nE 'deprecated|言い換え|文書化.*例外' plugins/dev-workflow/skills/specialist-validator/SKILL.md plugins/dev-workflow/skills/shared-artifacts/references/validation-report.md` の結果が **1 件以上**（validator または validation-report reference に deprecated 言い換えパターンが記載されている）
25. `ggrep -nE '上書き|null フィールド|既存 null|新フィールド' plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md` の結果が **1 件以上**（progress-yaml reference に新フィールド追加時の上書きルールが記載されている）

### D. リンク整合性

26. `ggrep -nE 'references/[a-z-]+\.md' plugins/dev-workflow/skills/dev-workflow/SKILL.md` で参照される全ファイルが実在する（手動目視確認 — リンク切れ 0 件）
27. `ggrep -nE 'references/[a-z-]+\.md' plugins/dev-workflow/skills/specialist-common/SKILL.md` で参照される全ファイルが実在する（手動目視確認 — リンク切れ 0 件）

### E. 既存機能の維持

28. `gwc -l plugins/dev-workflow/skills/specialist-*/SKILL.md` で各 specialist の本体行数が **既存比 +20% 以内** に収まる（追記による肥大化を抑制。ただし specialist-planner / specialist-architect は機能追加が多いため +30% 以内を許容）
29. 既存 ADR `doc/adr/2026-04-26-dev-workflow-rename-and-flatten.md` のフラット構造方針に違反しない（フェーズ概念を再導入しない、新ステップを追加しない）
30. 既存の grep ベース成功基準パターン (`grep -rnE -i 'self[-_]review|Self-Review' plugins/dev-workflow/` が 0 件等) を破壊しない（直前サイクルの達成状態を維持）

## 制約

### 技術的制約

- 全ファイルは Markdown / JSON / YAML のみ（実行コード非該当）
- macOS 環境のため `gsed` / `ggrep` / `gwc` を使用（`macos-cli-rules` スキル準拠）
- 大規模機械置換が発生する場合は **gsed `-e` 連鎖を禁止** し、2-phase placeholder で実施する（直前サイクル T2 chain bug の教訓を本サイクルでも適用）
- description 圧縮時、Claude Code の skill discovery エンジンが参照するキーワード（「Specialist 用」「Step N」「specialist-* 名」「Do NOT use for」等）は可能な限り保持する
- references/ 切り出し時、本体側のリンクは相対パス `references/<name>.md` で記述
- `dev-workflow/SKILL.md` の中間目標 500 行以下は固いライン。それを超える場合は「実機能不要」セクションのさらなる切り出しを検討

### 規範的制約

- `dev-workflow` の基本方針（Main-Centric Orchestration / One-Shot Specialist / Gate-Based Progression / Artifact-Driven Handoff / Project-Rule Precedence）は全継承
- 既存 ADR `doc/adr/2026-04-26-dev-workflow-rename-and-flatten.md` のフラット構造（フェーズ概念非導入）を維持
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
- 既存 ADR: `doc/adr/2026-04-26-dev-workflow-rename-and-flatten.md`
- 直前サイクル Intent Spec（番号シフト先例）: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/intent-spec.md`
- 既存スキル: `plugins/dev-workflow/skills/dev-workflow/SKILL.md`, `plugins/dev-workflow/skills/specialist-common/SKILL.md`, `plugins/dev-workflow/skills/specialist-*/SKILL.md` 全 9 体
- 既存 shared-artifacts: `plugins/dev-workflow/skills/shared-artifacts/SKILL.md` および `templates/`, `references/` 全般

## 未解決事項

(主要意思決定はユーザー要求 + intent-analyst による auto モード判断で確定済み。以下は Step 2 Research / Step 3 Design / Step 4 QA Design で確認・決定する細部)

- **`dev-workflow/SKILL.md` から切り出す references の最終ファイル分割**: 本 Intent Spec ではコミット規約 / プロジェクト固有ルール / 調整プロトコル / ロールバック早見表の 4 候補を挙げたが、実際の切り出し粒度（2 ファイルにまとめるか 4 ファイルに分割するか）は Step 3 Design で確定。500 行以下を達成できる最小分割を選ぶ
- **`specialist-common/SKILL.md` の references 切り出し範囲**: スコープ規律 / Git ガードレール / 命令形・具体性の 3 候補を挙げたが、180 行以下を達成するために追加で「並列起動時の挙動」「秘匿情報の取り扱い」も切り出す必要があるか Step 3 で判断
- **description 圧縮の文字数下限**: 本 Intent Spec では「700 文字以下」と統一基準を設定したが、Claude Code の skill discovery 精度を維持するため最小限のキーワード保持が必要。実装段階で各 specialist の trigger condition を実検証することは本サイクルでは不可（dogfood は次サイクル）。Step 3 Design で description テンプレート（共通フォーマット）を確定
- **specialist-common description の扱い**: specialist-common は他 specialist 本文から参照される設計のため、description は他より緩い制約で良いか（800 文字以下を許容するか）を Step 3 で確定
- **本文追記の重複回避方針**: gsed 2-phase placeholder ルールを specialist-implementer 本体と shared-artifacts/references/implementation-log.md の両方に書くと、bootstrap retrospective M#3 と同じ「真のソース重複」アンチパターンを再現するリスクあり。Step 3 で「真のソースは specialist-implementer 本体、reference は 1 行参照のみ」のような原則を確定
- **specialist-retrospective-writer 本体への追記 vs template 直接追加**: 「再活性化が 1 回以上発生したタスクの SHA 列挙」欄を retrospective.md template に追加するかどうかは Step 3 で決定。本サイクルで template 直接追加するか、specialist-retrospective-writer 本体に「該当時に動的に列挙する」と明記するかの 2 案
- **specialist-reviewer 本文の holistic 追記の現状確認**: 直前サイクルで holistic 観点の責務追加は実施済みのため、「design.md と実装の整合性チェックを Round 1 必須項目化」が既に反映されているかを Step 2 Research で確認し、未反映分のみ追記
- **task-plan の Wave 構造**: 本サイクルは構造圧縮 (A) → description 圧縮 (B) → 本文追記 (C, D) の論理的順序があるが、A と B は独立、A と C/D も独立のため Step 5 で並列 Wave 化が可能。具体 Wave 構造は Step 5 で確定
- **gsed 機械置換の有無**: 本サイクルは新規追記が中心で、機械置換は description フィールドの一括置換程度にとどまる見込み。仮に gsed 一括置換が発生する場合は 2-phase placeholder を必須とする
