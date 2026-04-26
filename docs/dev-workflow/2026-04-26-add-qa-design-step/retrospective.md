# Retrospective: 2026-04-26-add-qa-design-step

- **Identifier:** 2026-04-26-add-qa-design-step
- **Writer:** Main (retrospective-writer 役を兼任)
- **Created at:** 2026-04-26T19:50:00Z
- **Cycle started at:** 2026-04-26T13:00:00Z
- **Cycle completed at:** 2026-04-26T19:50:00Z
- **Duration:** 約 7 時間 (連続作業相当、対話・レビュー含む)

## サイクル概要

dev-workflow プラグインに新ステップ Step 4 "QA Design" を追加するメタサイクル。Intent Spec の成功基準を観測可能なテストケース集合 (qa-design.md) と本質ロジックの分岐図 (qa-flow.md) として確定させる新 Specialist `qa-analyst` を新設し、planner からテスト方針記述を剥離した。実装都合テスト (TC-IMPL-NNN) と本質テスト (TC-NNN) を ID prefix で区別しつつ、両方を qa-flow.md に網羅図示することで人間レビュアーの認知負荷を軽減する設計を採用した。

旧 9 step → 新 10 step 構造への移行に伴い、specialist スキル、agents、shared-artifacts (templates / references)、README、合計 ~30 ファイルを修正・新規作成した。Intent Spec の全 14 成功基準を Validation で実測し、すべて PASS。

## 良かった点 (うまく機能したパターン)

- **Intent Spec で成功基準を観測可能な形式で 14 件確定** (ファイル存在 + grep 件数 + 含まれる記述) → Validation 段階で機械的に PASS/FAIL を判定でき、主観判断ゼロ
- **Plan モードでの議論を Intent Spec に取り込む流れ** (確認質問 → ユーザー回答 → Intent Spec 改訂) → 仕様凍結が短時間で完了
- **2 軸抽象化 (実行主体 × 検証スタイル)** の決定を Plan モードで早期に確定したことで、後の reference / template 設計が一貫
- **設計段階での代替案分析 (5 トピック × 各 2-4 案)** → ユーザー指摘 (qa-flow.md は実装都合テストも図示) のように後段で方針が変わった際にも、影響範囲が局所的だった
- **gsed の placeholder 経由による複合表現保護** (Step 5 ↔ Step 6 → Step 6 ↔ Step 7) → 連鎖二重置換の罠を回避できた
- **TODO.md と TaskCreate の二重管理** (永続層 + 揮発層) → メタサイクルの長時間進行でも進捗追跡が安定
- **8 commits をタスク単位で分割** → ユーザーの GitHub レビュー時に変更を局所化、レビュー容易
- **dev-workflow を使って dev-workflow を更新するメタ作業** → 旧仕様で動作確認しつつ新仕様を構築、両者の整合性を体感的に検証できた

## 課題 (うまくいかなかった箇所)

- **progress.yaml の artifacts セクションでキー重複エラーが 2 回発生** (task_plan, self_review)。新フィールド追加時に既存 null フィールドを残してしまった。pre-commit hook (yaml syntax check) で検出されたため迷彩はないが、commit を 1 回追加する手間が生じた
- **gsed の連鎖二重置換問題** が複数回発生 (Step 5〜6 → Step 6〜6 になる)。事前の placeholder 設定が漏れた箇所で発生
- **shared-artifacts/references/* の一部が T6 範囲外だったことが Step 5 中に発覚** (design.md, retrospective.md, todo.md など)。task-plan で漏れたため、追加 gsed バッチで対応する必要があった
- **dev-workflow/SKILL.md の大規模修正 (T3) が 1 タスクに集約されていた** ため、L 数が多くレビューしにくい diff になった
- **本サイクルがメタサイクル (旧仕様で進行中に新仕様を構築) のため、本サイクル中は番号体系が新旧混在** → self-review-report.md と template の Target 行で乖離

### ループ回数の分析

| ステップ間ループ  | 回数 | 根本原因                                           |
| ----------------- | ---- | -------------------------------------------------- |
| Step 6 ↔ Step 7   | 0    | High 指摘 0 件で Self-Review 一発通過              |
| Step 7/8 → Step 3 | 0    | Design 段階での代替案分析が十分                    |
| Step 8 → Step 6   | 0    | External Review で Blocker 0 件                    |
| Step 5 のリトライ | 0    | Implementation 中の差し戻しなし                    |

→ ループ 0 回。設計品質と Self-Review 段階での丁寧な検証が功を奏した。

### Blocker 履歴

- なし (本サイクル中に Blocker 発生なし)

## 次回改善案

### プロセス改善

- **task-plan 作成時に「shared-artifacts/references/*」全件をスキャンして影響範囲を網羅する** ルールを planner reference に追記 (今回 T6 で漏れた具体ケースを反映)
- **progress.yaml 編集時は新フィールド追加と既存 null 削除を 1 回の Edit でセット**にする運用を documents 系 specialist (intent-analyst, architect, planner, qa-analyst, retrospective-writer) のスコープ外チェックリストに追記
- **gsed で機械置換する場合は事前に `Step \d+〜\d+|Step \d+ ↔ Step \d+|Step \d+\/\d+` を grep して全件 placeholder 化する**ルールを implementer reference に追記
- **大規模修正タスク (例: dev-workflow/SKILL.md 全面書き換え) は更にサブタスクに分解** (ステップテーブル / 全体図 / 詳細セクション / コミット規約 / 並列ガイド / ロールバック表 を別 subtask 化)

### スキル改善

dev-workflow プラグインのスキル (`dev-workflow` / `specialist-*` / `shared-artifacts`) への具体的な改善提案:

- `dev-workflow/SKILL.md`: gsed 機械置換時の placeholder 規約をベストプラクティスとして明記 (今回の経験を反映)
- `specialist-implementer/SKILL.md`: 「機械置換が含まれるタスク」の場合の事前 grep + placeholder 設定を作業手順に追加
- `specialist-planner/SKILL.md`: メタサイクル (workflow 自体の修正) の場合の影響範囲分析チェックリストを追加 (shared-artifacts/* / agents/* / README / ADR への波及確認)
- `shared-artifacts/references/progress-yaml.md`: 「新フィールド追加時は既存 null フィールドを置き換える (削除 → 追加ではなく上書き) 」運用ルールを明記

### Specialist プロンプト改善

- `intent-analyst`: メタサイクルの場合 (本サイクルのように workflow 自体を修正する) の Intent Spec 制約セクションに「番号体系の新旧混在期間」を明示するテンプレートを追加
- `researcher`: T2 (project-skills) のように「該当言語スキル」を棚卸しする観点をデフォルト Topic 一覧に追加
- `architect`: 代替案分析の数を「2-3 案」から「3-5 案」に増やす推奨 (今回 5 トピックで質が高かった)
- `planner`: メタサイクルの場合のタスク分解時に「機械置換に伴う影響範囲」を明示する補足ガイドを追加
- `implementer`: gsed 機械置換時の placeholder ベストプラクティス明記
- `self-reviewer`: メタサイクル特有の「番号体系の新旧混在」をレビュー観点として追加
- `reviewer`: 「backward-compatibility」観点をデフォルト 5 観点 (security/performance/readability/test-quality/api-design) に加えて 6 番目として推奨
- `validator`: 機械的検証で実施できる成功基準 (ファイル存在 + grep 件数 等) はバッチスクリプト化を推奨

## 再利用可能な知見

- **gsed の連鎖二重置換問題と placeholder 経由による回避** は、リネーム / 番号シフトを伴う任意の dev-workflow メタサイクルで再利用可能 (CLAUDE.md または `git-workflow` スキルへの memory 候補)
- **2 軸抽象化** (実行主体 × 検証スタイル) は qa-design 以外の文脈 (例: コードレビュー観点の整理、ロールアウト戦略の整理) でも適用可
- **メタサイクルの番号体系過渡期** という概念は、dev-workflow / プラグイン / フレームワーク自身を修正する任意のサイクルで再現する。Intent Spec で明示することで Validation 段階での誤検知を防げる
- **GitHub Mermaid レンダリングを前提とした文書設計** (qa-flow.md) は、レビュー認知負荷軽減の汎用パターン

## ユーザー承認ゲートの振り返り

- Step 1 (Intent Clarification): **3 ラウンド** (初回 → ADR 不要化 + Claude Code subagent 制約削除 → qa-flow.md 拡張子化と implementer 編集権限 → 承認)。3 回の改訂で意図を完全に確定できた
- Step 3 (Design): **2 ラウンド** (初回 draft 提示 → TC-NNN/TC-IMPL-NNN 区別の追加要請 → ID prefix で判別可能 + qa-flow に実装都合テストも反映の追加要請 → 承認)
- Step 4 (Task Decomposition): **1 ラウンド** ("go" の即承認)
- Step 7 (External Review): N/A (本サイクルでは Main 判定で完了、ユーザー承認ゲートなし)
- Step 8 (Validation): N/A (同上)

→ Step 1 と Step 3 で複数ラウンドあったが、すべてユーザー指示で意図が明確化した。意図の不明確さではなく、設計判断の精緻化が目的。

## In-Progress ユーザー問い合わせの振り返り

- 件数: 0
- 主要トピック: なし (本サイクルは AskUserQuestion での明確な選択肢提示でユーザー判断を仰いだため、`$TMPDIR/dev-workflow/*.md` 一時レポートは作成せず)

## コスト / 時間

- 各ステップの実時間 (大まか):
  - Step 1 (Intent Clarification): 約 1 時間 (3 ラウンド)
  - Step 2 (Research): 約 30 分 (5 観点、Explore × 2 並列 + 私が 3 観点直接調査)
  - Step 3 (Design): 約 1.5 時間 (2 ラウンド + Mermaid 図作成)
  - Step 4 (Task Decomposition): 約 30 分
  - Step 5 (Implementation): 約 2.5 時間 (8 タスク T1-T8)
  - Step 6 (Self-Review): 約 15 分
  - Step 7 (External Review): 約 30 分 (3 観点)
  - Step 8 (Validation): 約 5 分 (T8 機械検証の正式記録)
  - Step 9 (Retrospective): 約 30 分 (本ファイル)
- Specialist 起動回数: Main が全役を兼任 (Explore subagent × 2 のみ実起動)
- 並列度の実効: Step 2 (Research) で Explore × 2 並列 + 私が他 3 観点を直接調査 = 効率的並列。Step 5 は Wave 構造で計画したが、Main 兼任のため実質直列実行。本来の dev-workflow なら implementer × N 並列で大幅短縮可能
