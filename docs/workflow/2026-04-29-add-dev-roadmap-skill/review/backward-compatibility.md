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

| # | 項目 | 結果 |
| --- | ---- | ---- |
| 1 | 既存サイクル成果物の内容差分 (SC-12) | PASS |
| 2 | `progress.yaml` 既存フィールドの変更 | PASS (末尾追記のみ) |
| 3 | `progress.yaml.roadmap == null` (デフォルト) でのスキップ規則 | PASS (`dev-workflow/SKILL.md` 766-768 で fail-open 明記) |
| 4 | `dev-workflow/SKILL.md` 追記の独立サイクルへの非影響 | PASS (両セクションでスキップ規則一貫、`grep -nF "roadmap-progress.yaml"` = 11 件) |
| 5 | `specialist-common/SKILL.md` の Specialist 列挙拡張 | PASS (12 specialists 列挙、Do NOT use for 拡張、qa-analyst 重複追加なし、self-reviewer 復元なし) |
| 6 | `shared-artifacts/SKILL.md` の成果物一覧追加 | PASS (既存テーブル行不変、新規 4 行追加、1:1 例外 3 件目追記) |
| 7 | 既存テンプレート互換性 | PASS (`templates/progress.yaml:65` の `roadmap: null` 末尾追加で fail-open) |
| 8a | 物理ディレクトリリネーム | PASS (内容差分 0 リネームのみ) |
| 8b | スキル/agent/reference/template 内のパス参照表記 | **Major 指摘あり** (32 箇所残存) |

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

| 深刻度 | 件数 |
| ------ | ---- |
| Blocker | 0 |
| Major | 1 |
| Minor | 0 |
| Info | 1 |

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
