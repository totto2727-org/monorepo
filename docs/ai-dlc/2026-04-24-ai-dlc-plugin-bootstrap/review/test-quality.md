# Review Report: test-quality

- **Identifier:** 2026-04-24-ai-dlc-plugin-bootstrap
- **Aspect:** test-quality
- **Reviewer:** reviewer（Verification Step 7、test-quality 観点）
- **Reviewed at:** 2026-04-24T17:10:00Z
- **Scope:** `plugins/ai-dlc/` 配下の全プラグイン成果物（SKILL.md、agents/*.md、shared-artifacts references/templates、.claude-plugin/plugin.json）。Markdown-only プラグインのため、test-quality を以下に適応して評価する: (1) Triggering test（Should / Should NOT）の網羅性、(2) Exit Criteria / Gate の観測可能性、(3) 失敗モード / エッジケースの手順化、(4) Verifiability（第三者が動作確認できるか）、(5) Skill-reviewer G6（test strategy）観点。

## サマリ

| 深刻度      | 件数 |
| ----------- | ---- |
| Blocker     | 0    |
| Major       | 3    |
| Minor       | 5    |

**Gate 判定:** needs_fix（Blocker 0 件だが、Major 3 件はテスト観測点の欠落に関するもので、Verification 中に補強すべき）

## 指摘事項

### #1 Specialist スキル 9 本中 8 本に Triggering Test（Should / Should NOT）セクションが存在しない

- **深刻度:** Major
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/specialist-intent-analyst/SKILL.md`
  - File: `plugins/ai-dlc/skills/specialist-researcher/SKILL.md`
  - File: `plugins/ai-dlc/skills/specialist-architect/SKILL.md`
  - File: `plugins/ai-dlc/skills/specialist-planner/SKILL.md`
  - File: `plugins/ai-dlc/skills/specialist-self-reviewer/SKILL.md`
  - File: `plugins/ai-dlc/skills/specialist-reviewer/SKILL.md`
  - File: `plugins/ai-dlc/skills/specialist-validator/SKILL.md`
  - File: `plugins/ai-dlc/skills/specialist-retrospective-writer/SKILL.md`
- **問題の要約:** `specialist-implementer` のみ「トリガー想定例」セクションで Should trigger / Should NOT trigger の例を列挙しているが、他の 8 本の specialist-* スキルは description の Trigger 記述のみで、本文にテスト可能な形式（具体例列挙）が存在しない。Skill-reviewer の G6（test strategy）評価では「発火/非発火の観測点がセットで明記されているか」が基準となるため、再現性のある発火テストができない。
- **根拠:** `specialist-implementer` L76-79 には `Should trigger / Should NOT trigger` 例があるのに対し、他の 8 本は description の `起動トリガー:` / `Do NOT use for:` 記述のみ。スキル名 + 本文の具体例がないと、Claude Code の Skill マッチング挙動を第三者が検証できない。
- **推奨アクション:** 各 specialist-* スキルに `## トリガー想定例` セクションを追加し、description の Trigger ワードを本文内で 2–3 件ずつ具体例化する（`specialist-implementer` L76-79 の形式を踏襲）。
- **設計との関連:** Design Document「スキル命名規則」および `main-workflow` L464-479 の「起動テスト観点（Triggering 例）」の基本構造。main-* 側には類似セクションがあるが specialist-* 側は `specialist-implementer` のみ。

### #2 Validation Report テンプレートに「計測手段の前提が崩れた場合の記録欄」が欠如（エッジケース未対応）

- **深刻度:** Major
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/templates/validation-report.md`
  - File: `plugins/ai-dlc/skills/shared-artifacts/references/validation-report.md`
- **問題の要約:** `specialist-validator` SKILL.md L78 / 固有失敗モード表では「計測環境が用意できない」「成功基準が観測不能と判明」を Blocker として扱う指示があるが、`validation-report.md` テンプレートにはそのエッジケースを成果物側に記録する欄がない。結果として「未達でもなく、保留でもなく、観測不能だった」ケースが成果物から失われ、再開 / Retrospective での追跡が困難になる。
- **根拠:** テンプレート L8-17 のサマリ表は `PASS / FAIL / 保留` の 3 区分のみ。reference L72-77「観測の品質基準」では「保留がある場合、保留理由と計測不能な技術的背景が明示」とあるが、テンプレート側に対応するフィールドがない。
- **推奨アクション:** テンプレートに `観測不能（計測手段ブロック）` を保留のサブカテゴリとして明示し、「計測手段の制約」欄を追加する。または reference に「保留の判定ツリー（計測不能 / 一部制限 / 環境未整備）」を付け足して、テンプレートのプレースホルダと対応関係を取る。
- **設計との関連:** Design Document「観測可能性を担保する Validation」および成功基準 #7「全スキルが相互参照を通じて一貫した世界観を提示」。

### #3 Review Report テンプレートに「Blocker 0 件確認」欄・「他 reviewer と矛盾時の記録フォーマット」が不十分

- **深刻度:** Major
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/templates/review-report.md`
  - File: `plugins/ai-dlc/skills/specialist-reviewer/SKILL.md`
- **問題の要約:** `main-verification` L106「Blocker 指摘が 0 件」を Exit Criteria として要求し、L117 で「複数 reviewer の指摘が矛盾 → 両者の根拠を In-Progress 問い合わせ形式で提示」とあるが、`review-report.md` テンプレートの「他レビューとの整合性」セクション（L65-71）には「他 reviewer と矛盾した場合の記録例」が示されておらず、`{{cross_review_consistency}}` プレースホルダのみ。レビュアーが個別に記録形式を決めることになり、比較可能性が損なわれる。
- **根拠:** テンプレート L65-71 と specialist-reviewer L72「他 reviewer との指摘矛盾を検出したら記録」の仕様が噛み合っていない。記録フォーマットの欠落は、複数 reviewer の並列結果を Main が統合する段階で、観点間比較の観測可能性を損なう。
- **推奨アクション:** テンプレートに「矛盾あり / なし」のトグル、矛盾がある場合は「矛盾対象 Review Report パス / 矛盾点の要約 / 自分の根拠」の 3 フィールドを規定する。または reference に「矛盾記録の最小フォーマット」を明示し、テンプレートにプレースホルダとして反映する。
- **設計との関連:** `main-verification` L117 の矛盾処理仕様との整合。

### #4 `progress.yaml` の承認ゲート記録フォーマットがテスト観測点として参照されていない

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/references/progress-yaml.md`
  - File: `plugins/ai-dlc/skills/shared-artifacts/templates/progress.yaml`
- **問題の要約:** サイクル再開プロトコル（`main-workflow` L240-254）で `progress.yaml` の内容から現在地を復元するが、`user_approvals` / `blockers` / `active_specialists` の各フィールドの検証観測点（どの欄を見ればどのフェーズが進行中か）が reference に明示されていない。再開可能性の「観測可能性テスト」ができない。
- **根拠:** 成功基準 #6「ワークフロー中断時、`docs/ai-dlc/<identifier>/` 配下を読むだけで再開可能」を担保するには、`progress.yaml` の読み取り手順が明文化されている必要がある。現状は `main-workflow` L241-254 の再開プロトコル側に記載があるが、`progress-yaml.md` reference 側から相互参照されていない。
- **推奨アクション:** `progress-yaml.md` reference に「セッション再開時に読むフィールドの順序」セクションを追加、または `main-workflow` の再開プロトコルへのリンクを張る。
- **設計との関連:** 成功基準 #6「中断再開可能性」。

### #5 「テスト追加方針」が implementer のみに記述、自己レビューで検証する記録欄がない

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/specialist-implementer/SKILL.md` L61-62（テスト方針）
  - File: `plugins/ai-dlc/skills/shared-artifacts/templates/self-review-report.md`
  - File: `plugins/ai-dlc/skills/specialist-self-reviewer/SKILL.md`
- **問題の要約:** implementer にはテスト追加方針（境界値・エラーケース）の記述があるが、self-reviewer SKILL.md の観点リスト L41「テスト網羅性の明らかな不足」だけで、`self-review-report.md` テンプレートに「テスト網羅性の検証結果」を記録する専用フィールドがない。implementer→self-reviewer 間の品質基準が成果物レベルで接続されていない。
- **根拠:** self-review-report テンプレート側に専用の「テスト網羅性」サマリ欄があれば、Step 6 の Exit Criteria「High 0 件」の自動チェックがしやすい。
- **推奨アクション:** `self-review-report.md` テンプレートに「テスト網羅性チェック結果」（境界値 / 異常系 / 成功系 / スキップテストの有無）のチェックリスト欄を追加する。
- **設計との関連:** Step 6 Exit Criteria および `specialist-self-reviewer` L41 の観点。

### #6 task-plan 不変性の検証観測点が test-quality 観点から弱い

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/references/task-plan.md`
  - File: `plugins/ai-dlc/skills/main-construction/SKILL.md`
- **問題の要約:** Construction 中の `task-plan.md` 不変ルールは self-review #4（fixed）で文言統一されたが、「不変であることを自動検証できる観測点」（例: Git 差分チェック、ファイル mtime）が reference / SKILL どちらにも記述がない。人手ルールに頼っており、test-quality 観点では verifiability が弱い。
- **根拠:** Exit Criteria に「コミット後、次ステップ着手時に一時ファイル以外の差分がない状態」とあるが、これは task-plan 専用の観測ではなく、全成果物の一般則。task-plan 不変性は別軸の観測点が望ましい。
- **推奨アクション:** `main-construction` に「Step 5 中に `git diff task-plan.md` が空であることを各タスクコミット前に確認」の一文を追加する（軽量な verifiability 補強）。
- **設計との関連:** Design Document「task-plan 不変運用」の採用理由。

### #7 `intent-spec.md` 成功基準 `#3`「Claude Code 公式仕様と整合」の検証手段未定義

- **深刻度:** Minor
- **該当箇所:**
  - File: `docs/ai-dlc/2026-04-24-ai-dlc-plugin-bootstrap/intent-spec.md` L43
  - File: `plugins/ai-dlc/skills/shared-artifacts/references/intent-spec.md`
- **問題の要約:** 成功基準「Claude Code 公式仕様（サブエージェント階層制約）と整合した設計になっている」は抽象的で、`validator` がどう観測するかが未定義。intent-spec reference にも成功基準の「観測可能性」をチェックする手順例がない。
- **根拠:** Step 8 Validation で「観測値と目標値の比較」を徹底するには、成功基準の段階で観測手段をセットで決める必要がある（intent-spec reference にその要請を埋めるのが設計原則と整合）。
- **推奨アクション:** intent-spec reference に「観測可能性の自己チェック（基準ごとに観測手段を 1 行で添える）」を品質基準として追加する。既存 intent-spec.md はフォローアップとして更新。
- **設計との関連:** 「Validation は客観的な観測値との比較」の原則との整合。

### #8 Skills の description 先頭に `allowed-tools` が `shared-artifacts` のみに明示されている

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/SKILL.md` L12
  - 他 14 スキルの frontmatter
- **問題の要約:** `shared-artifacts` のみ `allowed-tools: Read, Glob, Grep` が明示されているが、main-* / specialist-* の他 14 スキルには記載がない。意図として「読み取り専用スキル」は `shared-artifacts` のみで、他は Write / Bash 等を許可したい可能性があるが、明示されていないと発火時の権限境界が観測不能。
- **根拠:** Skill-reviewer G6（test strategy）の副次観点として、許可ツール制約は発火テストの境界条件になる。
- **推奨アクション:** 各スキルに `allowed-tools` を明示する（少なくとも Main 側は `Read, Write, Edit, Bash, Task` が想定）。または Design Document に「allowed-tools を明示しないことの意図」を一文記録。
- **設計との関連:** Design Document「スキル構造」。

## 観点固有の評価項目

### エッジケース網羅

- ✅ 各 specialist-* の「固有の失敗モード」表は網羅的（4–5 ケース以上記載）
- ✅ `main-*` の「失敗時の挙動」セクションは差し戻し / 追加起動 / ロールバック の 3 軸で定義
- ⚠️ エッジケースの一部（計測不能 / task-plan 改変検出 / 並列 reviewer 矛盾）がテンプレート／reference 側の記録欄に反映されていない（#2 / #3 / #6）
- ⚠️ `$TMPDIR` アクセス前提が別セッション再開時に崩れる懸念（self-review #8 と整合）は test-quality 観点でも観測手段が欠落

### mock 戦略（N/A for markdown）

- 該当なし（Markdown-only プラグイン、実行可能コードなし）
- 代替として Specialist 起動の「1 Specialist = 1 ステップ」「ステップ跨ぎ禁止」ライフサイクル規律が、テスト独立性の類似概念として機能している

### テスト独立性

- ✅ `specialist-common` L53「1 Specialist = 1 ステップ」「セッション跨ぎの再利用禁止」がテスト独立性に相当する保証
- ✅ `implementer` L72-74 で並列起動時のファイル編集重複を明示的に禁止（独立性を担保）
- ⚠️ 並列 reviewer の矛盾検出（#3）だけ独立性の崩壊シナリオへの対処が弱い

### Verifiability（第三者観測可能性）

- ✅ Exit Criteria は観測可能な形式（ファイル存在 / 件数 / コミット済み状態）
- ✅ 成功基準はチェックボックス形式で 7 項目列挙（intent-spec L41-47）
- ⚠️ 成功基準 #3（Claude Code 公式仕様整合）は観測手段未定義（#7）
- ⚠️ 再開可能性テスト（成功基準 #6）の具体的読み取り順序が progress-yaml reference に不足（#4）

### Skill-reviewer G6（test strategy）適合度

- 8/15 スキル（main-inception / main-construction / main-verification / main-workflow / shared-artifacts / specialist-common / specialist-implementer ほか）に Triggering 例または Should/Should NOT 記述あり
- **8 本の specialist-* に Triggering 具体例が欠落**（#1）→ G6 部分適合にとどまる
- 全スキル共通で description の Trigger ワード / Do NOT use for は記載済み（最低限の条件は満たす）

## 他レビューとの整合性

- **self-review-report.md との関連:**
  - self-review #7（Mermaid レンダー検証）は verifiability 観点で隣接するが、test-quality では直接扱わない
  - self-review #8（Retrospective の `$TMPDIR` アクセス前提）は本レビュー観点固有評価「エッジケース網羅」の懸念と整合
  - self-review #5 / #6（specialist-common の入力契約統一 / specialist-common の命名）は readability 観点のため本レビューでは重複指摘しない
- **他 Review Report との想定整合:**
  - readability 観点と重複する可能性のある指摘（#1 Triggering 例欠落）は「test-quality は発火の観測可能性」「readability は description 文の明瞭性」と切り分ける。テンプレート追加を求めるのが test-quality 固有の主張
  - security / performance 観点とは独立（該当なし）
  - api-design 観点との接点は #3（Review Report テンプレート設計）にあるが、本指摘はテスト観測性（矛盾時の記録フォーマット）が主眼であり、api-design の後方互換性／契約明確性とは独立

- なし（他レビューと決定的に矛盾する指摘はない）
