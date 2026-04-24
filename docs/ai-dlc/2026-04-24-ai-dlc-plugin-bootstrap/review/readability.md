# Review Report: readability

- **Identifier:** 2026-04-24-ai-dlc-plugin-bootstrap
- **Aspect:** readability
- **Reviewer:** reviewer (Verification Step 7 / readability 観点)
- **Reviewed at:** 2026-04-24
- **Scope:** `plugins/ai-dlc/` 配下の全プラグイン成果物（`.claude-plugin/plugin.json` / `agents/*.md` / `skills/*/SKILL.md` / `skills/shared-artifacts/references/*.md` / `skills/shared-artifacts/templates/*`）。コード実装物は存在しないため「ドキュメントの命名・構造・記述一貫性・相互参照の正確性・新規利用者の読解フロー」を対象とする。

## サマリ

| 深刻度  | 件数 |
| ------- | ---- |
| Blocker | 0    |
| Major   | 3    |
| Minor   | 8    |

**Gate 判定:** needs_fix

## 指摘事項

### #1 specialist-* スキルのセクション構造が不統一（"ユースケースカテゴリ / 設計パターン" 行の欠落）

- **深刻度:** Major
- **該当箇所:**
  - Commit: 本サイクル現在の HEAD
  - File: `plugins/ai-dlc/skills/specialist-intent-analyst/SKILL.md` / `plugins/ai-dlc/skills/specialist-planner/SKILL.md` / `plugins/ai-dlc/skills/specialist-retrospective-writer/SKILL.md`
  - Line: H1 直下（各ファイルの 15–21 行目付近）
- **問題の要約:** 他の 6 個の specialist-* スキル（common / researcher / architect / implementer / self-reviewer / reviewer / validator）は H1 直後に「ユースケースカテゴリ: **Workflow Automation**」「設計パターン: **Sequential Workflow**（…）」の 2 行を置いてから「**継承:** `specialist-common`」に入るが、上記 3 ファイルだけはこの 2 行が欠落しており、いきなり「**継承:** `specialist-common`」で始まる。
- **根拠:** スキル群の section 構造は「役割位置づけの一瞥性」の基盤であり、同じ specialist-* 系列でフォーマットがブレると、新規利用者が「この specialist は他と違う種類のものか？」と誤解する。`main-*` スキルは全 4 ファイルで揃っており、specialist 系列だけが不揃い（9 ファイル中 3 ファイル欠落）。
- **推奨アクション:** 欠落している 3 ファイルの H1 直後に以下 2 行を挿入し、他の specialist-* と完全一致させる。
  - specialist-intent-analyst: `ユースケースカテゴリ: **Workflow Automation**` / `設計パターン: **Sequential Workflow**（対話ループで Intent Spec を精緻化）`
  - specialist-planner: 同上カテゴリ行 / `設計パターン: **Sequential Workflow**（設計読解 → 粒度分解 → 依存グラフ → Wave 識別）`
  - specialist-retrospective-writer: 同上カテゴリ行 / `設計パターン: **Sequential Workflow**（成果物・履歴収集 → 分析 → 改善案抽出）`
- **設計との関連:** `shared-artifacts` SKILL.md の「1:1 対応」「真のソース集約」方針と整合するため、specialist-* 群のフォーマット統一も同じ原則の適用対象。

### #2 frontmatter の `metadata:` フィールドが一部スキルでのみ存在

- **深刻度:** Major
- **該当箇所:**
  - File: 全 `plugins/ai-dlc/skills/*/SKILL.md`
  - 対象: `metadata` を持つのは `main-workflow` / `main-inception` / `main-construction` / `main-verification` / `specialist-implementer` / `specialist-planner` / `specialist-validator` / `specialist-retrospective-writer` の 8 ファイル。一方 `specialist-common` / `specialist-intent-analyst` / `specialist-researcher` / `specialist-architect` / `specialist-self-reviewer` / `specialist-reviewer` / `shared-artifacts` には `metadata:` ブロックが無い。
- **問題の要約:** 同一プラグイン内で `metadata.author` / `metadata.version` の有無が揃っておらず、版数追跡・著者明示の一貫性が崩れる。
- **根拠:** 新規利用者がスキル間を比較した際、`metadata` 有り無しが意味を持つのか（例: 「未記載のものは未ドラフトか」）と誤解する。プラグインの signalling が曖昧。
- **推奨アクション:** 全スキルに `metadata:\n  author: ai-dlc\n  version: 1.0.0` を統一して付与するか、逆に `plugin.json` に集約して SKILL.md からは省略する方針（どちらに寄せるかは Main に判断を仰ぐ）。
- **設計との関連:** `plugin.json` で既にプラグイン全体の `author` / `version` は宣言済みのため、SKILL.md 単位の `metadata` は重複情報になり得る点も検討材料。

### #3 テンプレートファイルのファイル名規約が不揃い（`TODO.md` / `progress.yaml` のみ大文字・別拡張子）

- **深刻度:** Major
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/templates/TODO.md` / `plugins/ai-dlc/skills/shared-artifacts/templates/progress.yaml`
  - 対比: 他は全て小文字ハイフン区切り `.md`（例: `intent-spec.md` / `design.md` / `task-plan.md` / `research-note.md` / `implementation-log.md` / `self-review-report.md` / `review-report.md` / `validation-report.md` / `retrospective.md`）
- **問題の要約:** references 側は `todo.md` / `progress-yaml.md` と小文字・ハイフン統一なのに対し、templates 側は `TODO.md`（大文字）と `progress.yaml`（拡張子違い）が混在。`shared-artifacts` SKILL.md が強調する「references と templates は **1:1 対応。同名ファイルで紐付く**」（line 28, 48）という仕様に自分自身で違反している。
- **根拠:** `shared-artifacts/SKILL.md` の表（line 36–46）でも `| 6 | TODO.md | ... | shared-artifacts/references/todo.md | shared-artifacts/templates/TODO.md |`、`| 1 | progress.yaml | ... | shared-artifacts/references/progress-yaml.md | shared-artifacts/templates/progress.yaml |` と、名前不一致を自ら明示している。「1:1 対応（同名）」という原則の信頼性が損なわれる。
- **推奨アクション:** いずれか方針を採用:
  - (A) 全テンプレートを小文字ハイフン `.md` に統一: `templates/todo.md` / `templates/progress.yaml` → `templates/progress.md`（YAML 内容を fence で囲む）。その上で reference を `todo.md` / `progress.md` に揃える。
  - (B) 原則を書き換える: 「references/templates はファイル名ではなく**識別子**で対応し、拡張子や記法の違いは各成果物フォーマットに従う」と明記し、1:1 対応表で読み替えを明示する。
  - いずれにせよ、原則と実態のどちらかを動かすこと。現状は両立できていない。
- **設計との関連:** `shared-artifacts` スキルの存在意義そのものが「真のソース 1:1 対応」なので、この指摘は同スキルの設計目的に直結。

### #4 「設計ドキュメント」「Design Document」「design.md」「設計書」の表記ゆれ

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/main-workflow/SKILL.md` line 144 / 164 / 182 / 219 / 287 / 455, `plugins/ai-dlc/skills/main-inception/SKILL.md` line 26 / 33 / 47 / 126 / 139 / 148 / 154, `plugins/ai-dlc/skills/specialist-architect/SKILL.md` line 65 / 67, `plugins/ai-dlc/skills/specialist-self-reviewer/SKILL.md` line 39 / 72, 他多数
- **問題の要約:** 同一概念に対して「設計ドキュメント」「Design Document」「`design.md`」の 3 表記が混在。文脈によってはサイクル固有の `design.md` ファイルのことを「設計書」と呼ぶ箇所もあり、読者が「設計ドキュメント本体」と「ADR」と「`design.md` ファイル」を同一視してよいか混乱する。
- **根拠:** 用語統一は新規利用者の学習コストに直結する。特に `specialist-architect` の「Design Document と ADR の役割分担」節（line 65）では「Design Document (`design.md`)」と明示する一方、他所では「設計ドキュメント」と日本語化され、両者が同じか読み取りづらい。
- **推奨アクション:** グロッサリを `shared-artifacts` SKILL.md 冒頭に追加: 「**Design Document / 設計ドキュメント / `design.md`** — いずれも `docs/ai-dlc/<identifier>/design.md` を指す。ADR（プロジェクト横断の意思決定）とは別概念」等。各スキルで初出時に `Design Document (`design.md`)` 形式を用い、以後は `design.md` に統一する方針を推奨。
- **設計との関連:** `design.md` と ADR の使い分けはプラグインの中核判断であり、用語ゆれは認知負荷増を生む。

### #5 Verification Step 6 ↔ Step 7 の「深刻度ラベル」の体系が非対称

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/specialist-self-reviewer/SKILL.md` line 64–67（High / Medium / Low）, `plugins/ai-dlc/skills/specialist-reviewer/SKILL.md` line 62–65（Blocker / Major / Minor）
- **問題の要約:** Self-Review は「High / Medium / Low」、External Review は「Blocker / Major / Minor」。同じ「レビューでの指摘の深刻度」でありながら、用いるラベル体系が異なる。`main-construction` / `main-verification` の記述でも同じラベルがそれぞれ使われるため、読者は「High = Blocker？ Medium = Major？」と脳内で翻訳が必要。
- **根拠:** 一般に OWASP / CWE / CVSS 等で混在する用法ではあるが、プラグイン内の 1 ワークフローとして統一が望ましい。特に `self-review-report` / `review-report` のテンプレートを見比べた読者は、命名選定の意図がなければ混乱する。
- **推奨アクション:** 以下いずれか。
  - (A) Self-Review と External Review で共通に「Blocker / Major / Minor」を用いる。High 相当を Blocker に、Medium を Major に、Low を Minor にマッピング。
  - (B) 意図的に非対称とする場合、`shared-artifacts/references/self-review-report.md` または `main-construction` 冒頭に「Self-Review では外部レビューと区別するため High/Medium/Low を用いる。対応関係は High≈Blocker、Medium≈Major、Low≈Minor」と明示する。
- **設計との関連:** 深刻度ラベルはゲート判定（`Step 6 は High 0`, `Step 7 は Blocker 0`）に直接関わるため、意味論の曖昧さはゲート判定自体の混乱を招く。

### #6 「プロジェクト固有ルール優先」節の大量重複

- **深刻度:** Minor
- **該当箇所:**
  - File: `main-workflow` SKILL.md line 277–325（「プロジェクト固有ルールとの関係」全節）, `main-inception` SKILL.md line 132 の Step 3 内, `main-construction` SKILL.md line 121, `main-construction` line 180, `main-verification` line 74, `specialist-common` SKILL.md line 31–40（「0. プロジェクト固有ルール優先」）, 各 specialist-* の冒頭「継承:」行
- **問題の要約:** 「プロジェクト固有ルール優先」メッセージが少なくとも 6 箇所で類似の内容を再掲。変更時の更新漏れリスク（Single-Source 原則への違反）と、読者の読み流し発生リスクが高い。
- **根拠:** `shared-artifacts` が「真のソース集約」を標榜するのに対し、Project-Rule Precedence は同原則から逸脱している。`main-workflow` 本文が真のソースならば、他所は「詳細は main-workflow 参照」で十分。
- **推奨アクション:** 真のソースは `main-workflow` の「プロジェクト固有ルールとの関係」とし、他ファイルでは以下を 1 行で記すに留める:
  - 「プロジェクト固有ルールは `main-workflow`「プロジェクト固有ルールとの関係」参照。Main は Specialist 起動時に該当スキルのパスを必ず入力に含める」
- **設計との関連:** `specialist-common` 冒頭「前提となる上位スキル」で既に `main-workflow` を参照しているため、重複は削除可能。

### #7 `intent-spec.md` 内の「成功基準」と Validation 観測値判定の整合性への記述不足

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/references/review-report.md` は読んだが `intent-spec.md` / `validation-report.md` 各 reference の定義上の統合ポイントに関する言及がやや希薄（各 reference 本文未読分も含む）
  - 具体的には `specialist-intent-analyst/SKILL.md` line 60–66 の「観測可能な成功基準のガイド」と `specialist-validator/SKILL.md` line 64–71 の「観測の品質基準」が、別々に記載され、相互リンクがない。
- **問題の要約:** Step 1 で定義された成功基準を Step 8 がどう観測するかのクロスリファレンスが張られておらず、「Step 1 で合意した計測手段」と「Step 8 で採用する計測手段」の一貫性を保証する導線が明示的でない。
- **根拠:** プロセス構造上、Intent Spec の成功基準が Validation の対象になる以上、両スキル間の明示的相互参照があったほうが新規利用者が追いやすい。
- **推奨アクション:** `specialist-intent-analyst` の「観測可能な成功基準のガイド」末尾に「Step 8 で `validator` が同じ計測手段でこれを PASS/FAIL 判定する（`specialist-validator` の「観測の品質基準」参照）」と追記。逆方向も同様。
- **設計との関連:** 成功基準の trace を 1 本の線として読めるようにするため。

### #8 agent `description` frontmatter に `Do NOT use for:` が一部だけ付いている

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/agents/reviewer.md` / `agents/retrospective-writer.md` / `agents/validator.md` は `Do NOT use for:` を含む。一方 `agents/intent-analyst.md` / `researcher.md` / `architect.md` / `planner.md` / `implementer.md` / `self-reviewer.md` は欠落。
- **問題の要約:** SKILL.md と違って agents/*.md は短い紹介カードだが、「誤起動防止のネガティブケース」を明示する agent と明示しない agent が混在するのは一貫性を欠く。
- **根拠:** Claude Code のエージェント自動選択に影響する。`specialist-*` SKILL.md では全員 `Do NOT use for:` を記載しているのに、agents/*.md でだけ漏れがあるのは転記漏れの可能性が高い。
- **推奨アクション:** 全 agents/*.md に `Do NOT use for:` を追加し、対応する specialist-* SKILL.md の `description` と平仄を揃える。
- **設計との関連:** `specialist-*` SKILL.md と `agents/*.md` の 1:1 対応を強化する。

### #9 「スコープ規律」節の見出しゆれ（「スコープ外（やらないこと）」 vs 「やってはいけないこと」）

- **深刻度:** Minor
- **該当箇所:**
  - File: 多数の `specialist-*/SKILL.md`（`スコープ外（やらないこと）` 見出し）vs `specialist-common/SKILL.md` line 155（`### やってはいけないこと`）
- **問題の要約:** `specialist-common` では「やってよいこと / やってはいけないこと」、他 specialist-* では「スコープ外（やらないこと）」と見出しが揺れる。新規利用者が両方を読んだとき「これらは同じ概念の別表現か？」と迷う。
- **根拠:** 一貫性のために見出しを揃えるのが望ましい。
- **推奨アクション:** `specialist-common` 5 節の見出しを「やってよいこと / **スコープ外（やってはいけないこと）**」に変更するか、逆に specialist-* を「やってはいけないこと」へ統一する。
- **設計との関連:** なし（純粋な表記統一）。

### #10 `shared-artifacts` SKILL.md の目次表で `progress-yaml.md` と `progress.yaml` がカラム間で対応しない

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/shared-artifacts/SKILL.md` line 36
- **問題の要約:** Reference が `progress-yaml.md` / Template が `progress.yaml` と示されており、直前の原則「references と templates は **1:1 対応。同名ファイルで紐付く**」（line 28, 48）に矛盾する（上記 #3 関連）。
- **根拠:** 本表と原則の自己整合が取れていない。
- **推奨アクション:** #3 の修正と合わせ、原則を書き換えるか、ファイル名を揃える。
- **設計との関連:** #3 と一体の問題。

### #11 Section numbering が `specialist-common` のみ 0–8 の数値節を使用

- **深刻度:** Minor
- **該当箇所:**
  - File: `plugins/ai-dlc/skills/specialist-common/SKILL.md` line 31, 44, 62, 80, 105, 147, 165, 175, 185（「0. プロジェクト固有ルール優先」「1. ライフサイクル規則」… 「8. 命令形・具体性の原則」）
- **問題の要約:** 他のスキルは番号なし H2。`specialist-common` だけが 0 始まり数字を付与しており、視覚的に異質。新規利用者がこの番号に意味があるのか判断に迷う（優先順位？ 実行順？）。
- **根拠:** プラグイン内の 1 スキルだけが番号形式を採るのは読解フロー上ノイズ。
- **推奨アクション:** 数字を削除し、他スキルと同じ番号なし H2 に統一するか、番号に明示的意味（「参照順ではなく単なる内部節番号」等）の注記を加える。
- **設計との関連:** なし（純粋な構造統一）。

## 観点固有の評価項目

### 命名（Naming）

- **Specialist / Agent / Skill 三層の命名対応**: `agents/<role>.md` ↔ `skills/specialist-<role>/SKILL.md` の 1:1 対応は 9 役割すべてで維持されており良好（intent-analyst / researcher / architect / planner / implementer / self-reviewer / reviewer / validator / retrospective-writer）。プレフィックス規約（`main-*` / `specialist-*` / `shared-artifacts`）も一貫。
- **例外**: `shared-artifacts` のみプレフィックス規則から外れるが、これは「成果物共有基盤」という位置づけの単独性からは自然。READMEレベルで「`shared-artifacts` は main / specialist いずれからも参照される中立基盤」と明示されていれば理想。
- **成果物ファイル名**: 上記 #3 / #10 を除いて、全て小文字ハイフン `.md` で統一できており良好。

### 責務分離（Responsibility Separation）

- **Main と Specialist の分離**は `main-workflow` line 65–101 で明確に記述され、オーバーラップが生じにくい。
- **各 specialist-\* の「スコープ外（やらないこと）」節**は、他 specialist との境界を具体名で指し示しており、読み手が責務の地図を掴みやすい。
- 一方、`specialist-self-reviewer` と `specialist-reviewer` の境界が「外部観点 vs 全体整合性」と概念的には説明されるが、具体例を挙げた境界定義（例: 「こういう指摘は self-reviewer が拾う / こういう指摘は reviewer が拾う」）が手薄。新規利用者は `self-reviewer` と `reviewer` がどちらも「全 diff を読んでレビューする」という共通点に惑わされやすい。
- 推奨: `shared-artifacts/references/self-review-report.md` 又は `review-report.md` に「Self-Review と External Review の境界早見表」を追加することで改善可能（本レビューのスコープでは未読のため、未追加ならば Major 寄りの指摘に昇格）。

### コメント品質（Comment Quality）

- プラグインはドキュメント集合体のためコード行コメントは対象外。代わりに「メタコメント」（表の補足 `<!-- 必要な数だけ追加 -->` 等）は templates に適切に配置されており、新規利用者がテンプレートをコピーしたあとにコメントを残すか削除するかを明示できている。
- **改善余地**: `review-report.md` テンプレート（line 45, 51, 57, 63 等）のヒントコメントは、具体例を含むので有用。一方 `specialist-retrospective-writer` の「良かった点の抽出」等は、テンプレート側の雛形が未読のため整合性未確認（未レビュー範囲）。

### 型レベル表現（Type-level Expressions）

- ドキュメント中心のため厳密な「型」は存在しないが、**表（Markdown table）による役割・成果物・ゲート判定の型付け**は充実しており良好。`main-workflow` のワークフロー ASCII 図（line 106–128）、Implementation ↔ Self-Review ループ図（`main-construction` line 227–250）は視覚的理解を大きく助ける。
- `progress.yaml` のスキーマが `shared-artifacts/references/progress-yaml.md` に集約されている設計（ファイル名一致の件を除けば）は、型スキーマを 1 点集約する意図が明確。
- 改善余地: 成果物間の状態遷移（`task-plan.md` → `TODO.md` → TaskCreate）の「型変換ポイント」を Mermaid などの図で示すと、新規利用者の理解が加速する。

## 他レビューとの整合性

- 本サイクルは Verification Step 7 の観点並列レビュー（readability / security / performance / test-quality / api-design 等）として構成される想定。本レポートは **readability 単独** の視点であり、以下の観点との相互影響が想定される:
  - **test-quality 観点**: プラグイン自体に自動テストが存在しないが、「スキルの triggering テスト」節（`main-workflow` line 464–479、`specialist-implementer` line 76–79、`shared-artifacts` line 187–201）の一貫性は test-quality の範疇とも解釈可能。指摘 #1 / #8 は両観点にまたがる。
  - **api-design 観点**: Specialist 起動時の入力契約（`specialist-common` line 60–76、各 agents/*.md「Main への要求」）は API デザインに相当する。指摘 #8（Do NOT use for の欠落）は api-design 観点からは Major 相当になる可能性。
  - **security 観点**: 本レビューでは security 固有の指摘は検出せず。ただし `$TMPDIR` 配下の一時レポートの扱い（`main-workflow` line 408–412）に「機密情報を含むなら削除」と記述があるのみで、誰がその判定を下すかの責任者記述が弱い点は security レビューが別途検出する可能性あり。
- 他レビューの結果との **矛盾する指摘は検出していない**（本レビュー単独実施時点）。Main が他観点レビューの結果と付き合わせ、必要なら本レポートに追記する。
