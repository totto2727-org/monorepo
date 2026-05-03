# Review Report: Backward Compatibility

- **Cycle:** 2026-04-29-add-dev-roadmap-skill
- **Aspect:** backward-compatibility
- **Reviewer:** reviewer (single instance, aspect-scoped)
- **Created at:** 2026-05-01T07:30:00Z

## 担当観点

**backward-compatibility** — 既存サイクル動作および既存 dev-workflow / shared-artifacts スキル機能への非破壊性

## 要約 (3 行)

- 本サイクルが追加・改変したファイルそのものは Intent Spec 後方互換性ポリシー (SC-6 / SC-12) に厳密に適合し、既存サイクル成果物の内容差分は 0、`progress.yaml` テンプレートも追記のみで既存フィールド順序・型・既存サイクル `progress.yaml` のパース可能性を保持している。
- ただし T0 でのディレクトリ物理リネーム (`docs/dev-workflow/` → `docs/workflow/`) と T8/T9/T10 で改変した 3 ファイル内のパス置換のみが実装され、**他の既存スキル / agent / reference / template 計 32 件以上のファイルでは `docs/dev-workflow/<identifier>/` 表記が残存**しており、これら旧表記は新規サイクル起動時に Specialist へ「物理的に存在しない保存先」を案内する経路として残っている (新規サイクルの動作不整合誘発リスク)。
- design.md L529 が Step 8 Validation で `ggrep -rn "docs/dev-workflow" plugins/dev-workflow/` を「リネーム後 0 件」と要求している基準と、Step 6 完了時点の現状が乖離している (Step 8 Validation でもこれが Failure として顕在化する見込み)。

## SC-12 検証結果 (要件: ベースライン → HEAD で `docs/workflow/2026-04-26-add-qa-design-step/` 配下が「リネームのみ、内容差分 0」)

- **PASS**
- 検証コマンド: `git diff --find-renames 8444fb4..HEAD -- docs/workflow/2026-04-26-add-qa-design-step/ docs/dev-workflow/2026-04-26-add-qa-design-step/`
- 結果: 全 14 ファイルが `similarity index 100%` の純粋リネームのみで、内容差分 0 行。
- ベースライン特定: `progress.yaml.rollbacks[0].at = 2026-04-29T07:00:00Z`、当該時点の HEAD は main マージ直後コミット `8444fb4`。

## チェックリスト別検証結果

| #   | 項目                                                          | 結果                                                                                             |
| --- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| 1   | 既存サイクル成果物の内容差分 (SC-12)                          | PASS                                                                                             |
| 2   | `progress.yaml` 既存フィールドの変更                          | PASS (末尾追記のみ)                                                                              |
| 3   | `progress.yaml.roadmap == null` (デフォルト) でのスキップ規則 | PASS (`dev-workflow/SKILL.md` 766-768 で fail-open 明記)                                         |
| 4   | `dev-workflow/SKILL.md` 追記の独立サイクルへの非影響          | PASS (両セクションでスキップ規則一貫、`grep -nF "roadmap-progress.yaml"` = 11 件)                |
| 5   | `specialist-common/SKILL.md` の Specialist 列挙拡張           | PASS (12 specialists 列挙、Do NOT use for 拡張、qa-analyst 重複追加なし、self-reviewer 復元なし) |
| 6   | `shared-artifacts/SKILL.md` の成果物一覧追加                  | PASS (既存テーブル行不変、新規 4 行追加、1:1 例外 3 件目追記)                                    |
| 7   | 既存テンプレート互換性                                        | PASS (`templates/progress.yaml:65` の `roadmap: null` 末尾追加で fail-open)                      |
| 8a  | 物理ディレクトリリネーム                                      | PASS (内容差分 0 リネームのみ)                                                                   |
| 8b  | スキル/agent/reference/template 内のパス参照表記              | **Major 指摘あり** (32 箇所残存)                                                                 |

## 指摘事項

### Major-1: 既存スキル / agent / reference / template の path 表記が `docs/dev-workflow/` のまま残存 (32 箇所)

**該当ファイル群** (個別行番号は実装 commit 時点の状態):

- `plugins/dev-workflow/agents/architect.md:22`
- `plugins/dev-workflow/agents/intent-analyst.md:22`
- `plugins/dev-workflow/agents/planner.md:22`
- `plugins/dev-workflow/agents/qa-analyst.md:25, 26`
- `plugins/dev-workflow/agents/researcher.md:22`
- `plugins/dev-workflow/agents/reviewer.md:27`
- `plugins/dev-workflow/agents/validator.md:25`
- `plugins/dev-workflow/skills/specialist-architect/SKILL.md:27`
- `plugins/dev-workflow/skills/specialist-implementer/SKILL.md:75`
- `plugins/dev-workflow/skills/specialist-intent-analyst/SKILL.md:28`
- `plugins/dev-workflow/skills/specialist-planner/SKILL.md:31`
- `plugins/dev-workflow/skills/specialist-qa-analyst/SKILL.md:31`
- `plugins/dev-workflow/skills/specialist-researcher/SKILL.md:27`
- `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md:32`
- `plugins/dev-workflow/skills/specialist-validator/SKILL.md:26, 70`
- `plugins/dev-workflow/skills/shared-artifacts/references/{intent-spec,research-note,task-plan,todo,review-report,validation-report,qa-design,design,implementation-log,qa-flow,retrospective,progress-yaml}.md:15-17` (12 ファイル)
- `plugins/dev-workflow/skills/shared-artifacts/templates/{qa-design,validation-report}.md:40, 54` (2 ファイル)

**深刻度: Major**

**後方互換性への影響:**

1. 既存ベースラインでも `docs/dev-workflow/` 表記だったため、本サイクルが「既存スキルの後方互換性を悪化させた」とまでは言えない (Blocker ではない)。
2. しかし本サイクルは `docs/dev-workflow/` 物理ディレクトリを `docs/workflow/` にリネーム済のため、**残存する旧パス表記は実存しないディレクトリを指している**。Specialist が指示通り `docs/dev-workflow/<identifier>/` にファイル作成した場合、新規ディレクトリ作成によって意図せず `docs/dev-workflow/` 配下が再生成され、リポジトリの統一性が破壊される経路が成立する。
3. 影響を受けるのは **新規サイクル起動時** であり、既存完了サイクルには影響しない (SC-12 観点では純粋に PASS)。

**推奨アクション:**

`TODO.md` 後発追加タスクとして **T13: 既存スキル/agent/reference/template の path 一括置換** を追加し、`ggrep -rl "docs/dev-workflow/<" plugins/dev-workflow/ | xargs gsed -i 's#docs/dev-workflow/<#docs/workflow/<#g'` 相当の機械置換を全 32 箇所に適用する。Step 8 Validation で `ggrep -rn "docs/dev-workflow" plugins/dev-workflow/` が 0 件 (または ADR 等の歴史的記述のみ) になることを確認する。

### Info-1: `docs/adr/2026-04-26-dev-workflow-rename-and-flatten.md` 内の歴史的 path 表記

- **該当箇所**: `docs/adr/2026-04-26-dev-workflow-rename-and-flatten.md:93`
- **影響**: ADR 内の歴史的決定の記述であり、当時の決定事項を記録するために `docs/dev-workflow/` 表記を維持するのは適切
- **アクション**: 不要 (記録の正確性のため現状維持を推奨)

## 深刻度別件数

| 深刻度  | 件数 |
| ------- | ---- |
| Blocker | 0    |
| Major   | 1    |
| Minor   | 0    |
| Info    | 1    |

## 総合判定

- 本サイクルが Intent Spec 成功基準 (SC-6 / SC-12 / SC-13 等の後方互換性関連) を機械的に充足しているか: **YES** (全項目 PASS)
- 既存サイクル動作の非破壊性: **YES** (内容差分 0、SC-12 PASS)
- 既存 dev-workflow / shared-artifacts スキル本体の機能の非破壊性: **YES** (改変は追記主体、既存記述の意味論的変更なし)
- 新サイクル起動時の整合性: 既存 specialist/agent/reference/template の path 置換漏れに起因する **Major 指摘 1 件**。Step 8 Validation で `ggrep -rn "docs/dev-workflow" plugins/dev-workflow/` の 0 件要件と現実が乖離する見込み

## 検証ログ

- SC-12 主要検証: `/tmp/claude-501/sc12-diff.txt` (60 行、全リネームのみ確認)
- 全 path 残存件数調査: `/tmp/claude-501/all-paths.txt` (231 件)
- プラグイン内取りこぼし: `/tmp/claude-501/non-cycle-paths.txt` (32 件、本指摘の対象)
- 改変 3 ファイルの diff: `/tmp/claude-501/{dev-workflow-skill,specialist-common,shared-artifacts,progress-yaml}-diff.txt`

---

## Round 2 (post-Minor-fix re-review)

# Review Report: Backward Compatibility (Round 2)

- **Identifier:** 2026-04-29-add-dev-roadmap-skill
- **Aspect:** backward-compatibility
- **Reviewer:** reviewer (single instance, aspect-scoped, Round 2)
- **Reviewed at:** 2026-05-03T11:30:00Z
- **Scope:** Round 2 で追加された Minor 修正 (metadata.version 削除 9 ファイル / dev-workflow/SKILL.md L792 コミットメッセージ例修正 / validation-evidence/ ディレクトリ廃止 + validation-report.md インライン化 / 既存 specialist-\* SKILL.md frontmatter 影響確認) の後方互換性影響。Round 1 で指摘済の path 残存 32 箇所 (T13 で修正済) の現状再確認も含む。Round 1 で PASS した SC-12 主要検証は再実施で再確認するが、サイクル成果物全体の品質再評価は対象外。

## サマリ

| 深刻度  | 件数 |
| ------- | ---- |
| Blocker | 0    |
| Major   | 0    |
| Minor   | 0    |
| Info    | 2    |

**Gate 判定:** approved

## SC-12 検証結果 (要件: ベースライン → HEAD で `docs/workflow/2026-04-26-add-qa-design-step/` 配下が「リネームのみ、内容差分 0」)

- **PASS**
- 検証コマンド: `git diff --find-renames 8444fb4..HEAD -- docs/workflow/2026-04-26-add-qa-design-step/ docs/dev-workflow/2026-04-26-add-qa-design-step/`
- 結果: 全 14 ファイルが `similarity index 100%` の純粋リネームのみ。内容差分 0 行を維持。Round 2 修正でも既存サイクル成果物への影響なし。
- ベースライン: `8444fb4` (Round 1 で確定したベースライン、本 Round でも維持)。

## チェックリスト別検証結果

| #   | 項目                                                                                | 結果 |
| --- | ----------------------------------------------------------------------------------- | ---- |
| 1   | 既存サイクル成果物の内容差分 (SC-12)                                                | PASS |
| 2   | metadata.version 削除が specialist-\* SKILL.md の Specialist 起動契約に影響しないか | PASS |
| 3   | validation-evidence/ 削除がリポジトリ他箇所からの参照を破綻させていないか           | PASS |
| 4   | dev-workflow/SKILL.md L792 コミットメッセージ例修正と既存サイクル過去履歴の整合性   | PASS |
| 5   | Round 1 指摘の path 残存 32 箇所が現在 0 件か (再確認)                              | PASS |

## 検証ログ

### #1 SC-12: 既存サイクル成果物の内容差分

```bash
git diff --find-renames 8444fb4..HEAD -- docs/workflow/2026-04-26-add-qa-design-step/ docs/dev-workflow/2026-04-26-add-qa-design-step/
```

- 出力: 60 行のリネームエントリ、全 14 ファイルが `similarity index 100%`
- 内容差分: 0 行 (全エントリが `rename from` / `rename to` の対のみ、+/- diff 行なし)
- 判定: **PASS**

### #2 metadata.version 削除の影響確認

```bash
ggrep -rn "version:" plugins/dev-workflow/skills/*/SKILL.md
```

- 出力: 0 件 (全 SKILL.md から `version:` フィールドが削除済)
- 削除対象 9 ファイル (commit `648e233`):
  - dev-workflow/SKILL.md, dev-roadmap/SKILL.md
  - specialist-architect/SKILL.md, specialist-common/SKILL.md, specialist-intent-analyst/SKILL.md, specialist-planner/SKILL.md, specialist-qa-analyst/SKILL.md, specialist-researcher/SKILL.md, specialist-reviewer/SKILL.md, specialist-roadmap-analyst/SKILL.md, specialist-roadmap-planner/SKILL.md
- 影響評価:
  - Skill 起動契約は frontmatter `name` / `description` フィールドに依存し、`metadata.version` は記述メタ情報 (descriptive metadata) であって機能的契約 (functional contract) ではない
  - `metadata:` ブロック自体は維持され `author: totto2727` のみが残存 — Skill 認識・起動に必要な要素は不変
  - `ggrep -rn "metadata:" plugins/dev-workflow/skills/*/SKILL.md` で 15 件残存を確認 (frontmatter 構造維持)
- 判定: **PASS** — 後方互換性に影響なし。Specialist 起動契約への副作用ゼロ

### #3 validation-evidence/ ディレクトリ廃止の影響確認

```bash
ggrep -rn "validation-evidence" --include="*.md" --include="*.yaml"
ls docs/workflow/2026-04-29-add-dev-roadmap-skill/validation-evidence/  # No such file or directory
```

- 出力: 33 件 (3 カテゴリに分類)
- 物理ディレクトリ: 削除済 (commit `6eae32b` で 4 ファイル合計 104 行を validation-report.md にインライン化、+96 insertions)

#### カテゴリ A: shared-artifacts 規定 (8 件) — 影響なし

- `dev-workflow/SKILL.md:134, 496, 502, 711` (validator ステップの成果物欄)
- `shared-artifacts/SKILL.md:137` (構造ツリー図)
- `shared-artifacts/templates/validation-report.md:54, 86, 88, 89` (テンプレート内のオプショナル記述)
- `shared-artifacts/references/validation-report.md:17, 44, 68, 75` (書き方ガイド)
- `specialist-validator/SKILL.md:70, 78`
- `specialist-common/SKILL.md:212` (秘匿情報取扱対象に含む)

→ いずれも `validation-evidence/` を「**大きな証跡を保存する場合のオプション**」として規定する一般的記述。本サイクルが廃止したのは「本サイクル固有の証跡保存」のみであり、shared-artifacts 規定 (= テンプレート/書き方ガイドが提示する将来サイクルでの利用可能性) は維持されているため、参照破綻はない。

#### カテゴリ B: 本サイクルの自己参照 (5 件) — 後方互換性影響なし、Info-1 として記録

- `qa-design.md:75, 76` — Step 4 で書かれた「`automated × assertion` テストの推奨配置先」記述
- `manual-tests/TC-025.md:118`, `manual-tests/TC-032.md:107` — 結果記録テンプレートの「`validation-report.md` または `validation-evidence/<TC-ID>.md` に記録」
- `review/holistic.md:87` — Round 1 holistic レビュー内の言及

→ qa-design.md / manual-tests/ は immutable 原則 (qa-analyst Step 4 / implementer Step 6 の確定成果物) で原則上 Round 2 修正対象外。`validation-report.md` の選択肢が文中で並記される構造 (「`validation-report.md` **または** `validation-evidence/<TC-ID>.md`」) のため、validation-evidence/ 不在時の代替動線 (validation-report.md インライン記録) は文言上担保されている。後方互換性破綻なし (Info-1 で記録)。

#### カテゴリ C: 他サイクル / 本サイクルの最新成果物 (5 件) — 影響なし

- `docs/retrospective/2026-04-29-add-dev-roadmap-skill.md:60, 107` — Round 2 で生成された retrospective、validation-evidence/ への過去言及
- `docs/workflow/2026-04-24-ai-dlc-plugin-bootstrap/review/api-design.md:49, 133`, `security.md:66`, `validation-report.md:167` — 別サイクルの完了済成果物 (immutable)
- `docs/workflow/2026-04-29-integrate-self-review-into-external/validation-report.md:193`
- `docs/workflow/2026-04-29-retro-cleanup/validation-report.md:109`
- `docs/workflow/2026-04-29-add-dev-roadmap-skill/progress.yaml:6, 61, 150`, `validation-report.md:314` — 本サイクル内の Round 2 修正記録 (廃止理由を明示)

→ 全て歴史的記述または本サイクルの修正記録であり、参照破綻なし。

- 判定: **PASS** — `validation-evidence/` 削除によるリポジトリ参照破綻はゼロ

### #4 dev-workflow/SKILL.md L792 コミットメッセージ例修正

```bash
git diff 6eae32b~..6eae32b -- plugins/dev-workflow/skills/dev-workflow/SKILL.md
```

- 修正内容: `unlink milestone <milestone-id>` → `complete milestone <milestone-id>` に変更、追記で「`workflow_identifiers[]` は append-only で削除しない (= unlink 操作は存在しない、`complete` は `status: active → completed` 遷移を表す)」を明記
- 既存コミット履歴との矛盾検証:

  ```bash
  git log --all --oneline | ggrep -E "unlink milestone|complete milestone"
  ```

  - 出力: 0 件 — 過去に `unlink milestone` または `complete milestone` を使ったコミットは存在しない
  - 既存ロードマップ運用コミット (例: `5d5208a`, `686f4bf`, `0b6dfed`, `de0adb4` の `dev-roadmap/feed-platform` サイクル群) は一般的な docs/fix prefix を使用しており、修正後のコミットメッセージ例形式と整合

- 設計整合性検証: `templates/roadmap-progress.yaml` および `references/roadmap-progress-yaml.md` で `workflow_identifiers[]` が append-only と規定されているため、`unlink` 動詞は設計と矛盾する誤記であり、`complete` への変更は設計と整合する正しい修正
- 判定: **PASS** — 既存サイクル過去履歴と矛盾なし、設計仕様 (append-only スキーマ) との整合性向上

### #5 Round 1 path 残存 32 箇所の現状再確認

```bash
ggrep -rn "docs/dev-workflow/<" plugins/dev-workflow/
```

- 出力: 0 件
- 修正コミット: T13 (`37eb0d3`) で 29 ファイル + T14 (`aa14c1e`) + T15 (`551e497`) で残余を完全置換
- Round 1 Major-1 完全解消を再確認
- 判定: **PASS**

## 観点固有の評価項目 (backward-compatibility)

- **既存サイクル成果物の互換性:** PASS — リネームのみ、内容差分 0 (SC-12 で機械的に検証)
- **既存スキル機能の非破壊性 (Specialist 起動契約):** PASS — frontmatter `name` / `description` 維持、metadata.version 削除は記述メタの整理のみで起動契約に影響なし
- **既存テンプレート互換性:** PASS — Round 1 で確認済 (`templates/progress.yaml:65` の `roadmap: null` 末尾追加は fail-open)、Round 2 で再変更なし
- **物理ディレクトリ参照整合性:** PASS — Round 1 Major-1 完全解消、validation-evidence/ 削除に伴うリポジトリ内参照破綻もゼロ
- **コミットメッセージ規約整合性:** PASS — `complete milestone` は append-only スキーマと整合、既存コミット履歴と矛盾なし

## Info 指摘 (記録のみ、修正不要)

### Info-1: qa-design.md L75-76 / manual-tests/TC-025.md L118 / TC-032.md L107 内の `validation-evidence/` 言及

- **該当箇所:**
  - `docs/workflow/2026-04-29-add-dev-roadmap-skill/qa-design.md:75-76`
  - `docs/workflow/2026-04-29-add-dev-roadmap-skill/manual-tests/TC-025.md:118`
  - `docs/workflow/2026-04-29-add-dev-roadmap-skill/manual-tests/TC-032.md:107`
- **観察事実:**
  - qa-design.md は Step 4 で「`validation-evidence/` 配下に検査スクリプトを作成することを推奨」と記述
  - manual-tests/TC-\*.md は Step 6 で「`validation-report.md` または `validation-evidence/<TC-ID>.md` に記録」と並記
  - Round 2 で validation-evidence/ ディレクトリは廃止されたが、文言は immutable 原則で残存
- **後方互換性への影響:** なし
  - qa-design.md / manual-tests/TC-\*.md は確定済成果物 (immutable) であり、Round 2 で意図的に変更しなかった判断は dev-workflow の immutable 原則と整合
  - manual-tests/TC-\*.md は「validation-report.md または validation-evidence/<TC-ID>.md」の **OR 文言**で代替動線が文中で担保されており、validation-evidence/ 不在時も validation-report.md にインライン記録できる (実際に Round 2 でその経路が選択された)
  - qa-design.md L75-76 は「Step 5 planner / Step 6 implementer が確定」の方針提示であり、最終的に validator が validation-report.md インライン化を選択した結果との不整合は発生していない
- **アクション:** 不要 (immutable 原則維持、文言上の代替動線で実態と整合)

### Info-2: ADR `docs/adr/2026-04-26-dev-workflow-rename-and-flatten.md` 内の `docs/dev-workflow/` 表記

- **該当箇所:** `docs/adr/2026-04-26-dev-workflow-rename-and-flatten.md:93`
- **観察事実:** ADR 内の歴史的決定の記述として旧パス `docs/dev-workflow/` を維持
- **アクション:** 不要 (Round 1 と同じ判定、記録の正確性のため現状維持)

## 修正ラウンド履歴

| Round | Blocker | Major | Minor | 主要指摘 (要約)                                                                                                                                                                      | 修正コミット SHA                                 |
| ----- | ------- | ----- | ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------ |
| 1     | 0       | 1     | 0     | 既存スキル/agent/reference/template の path 表記が `docs/dev-workflow/` のまま 32 箇所残存 (Major-1)                                                                                 | `37eb0d3`, `aa14c1e`, `551e497`                  |
| 2     | 0       | 0     | 0     | Round 1 Major-1 完全解消を再確認、Round 2 の Minor 修正 (metadata.version 削除 / Mermaid 化 / commit message 訂正 / validation-evidence インライン化) はいずれも後方互換性に影響なし | (Round 2 自体は本レビュー対象、修正コミットなし) |

## 他レビューとの整合性

- なし (Round 2 では本観点のみが新規実施)

## 総合判定

- 本サイクルが Intent Spec 後方互換性関連 (SC-6 / SC-12 / SC-13) を機械的に充足しているか: **YES** (全項目 PASS)
- 既存サイクル動作の非破壊性: **YES** (SC-12 PASS、内容差分 0)
- 既存 dev-workflow / shared-artifacts / specialist-\* スキル本体の機能の非破壊性: **YES** (Round 2 修正は記述整理 / 表記統一 / オプショナルディレクトリ廃止のみで意味論的変更なし)
- 新サイクル起動時の整合性: **YES** (Round 1 Major-1 完全解消済、Round 2 修正は新サイクル動作に新たなリスクを導入しない)
- Round 2 の修正がもたらす後方互換性リスク: **ゼロ件**

## 検証ログ参照

- SC-12 検証出力: `/tmp/claude/sc12-r2.txt` (60 行、全リネームのみ確認)
- validation-evidence 参照調査: `/tmp/claude/val-evidence-refs.txt` (33 件、3 カテゴリ分類済)
- path 残存再確認: `/tmp/claude/path-residual-r2.txt` (0 件)
- Round 2 修正コミット範囲: `648e233`, `6eae32b`, `e01d03c`, `165ae8e`, `2cf1037`, `556cd32`
