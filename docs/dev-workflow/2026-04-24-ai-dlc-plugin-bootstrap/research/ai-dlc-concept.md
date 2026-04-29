# Research Note: AI-DLC Concept and Workflow Design Patterns

- **Identifier:** 2026-04-24-ai-dlc-plugin-bootstrap
- **Topic:** ai-dlc-concept
- **Researcher:** Main（設計者自身の知識 + 一般的な開発ライフサイクル研究）
- **Created at:** 2026-04-24T13:26:00Z
- **Scope:** AI-DLC (AI-Driven Development Lifecycle) の一般的な構成と、本プラグインで採用すべきフェーズ構成

## 調査対象

AI-DLC という概念の業界的な整理と、それを Claude Code 上のマルチエージェントワークフローに落とし込む際の推奨パターン。

## 発見事項

- AWS 等が提唱する "AI-DLC" は一般に **Inception → Construction → Operations** の 3 フェーズ構成
- 各フェーズは iterative（反復的）で、ゲート式進行と成果物駆動ハンドオフが特徴
- Agents Team 前提のマルチエージェント運用では、以下のパターンが有効:
  - **Sequential Workflow** — 順序付き処理、ステップ間依存、バリデーションゲート
  - **Multi-Service Coordination** — 複数サービス（エージェント）連携、フェーズ分離
  - **Iterative Refinement** — 生成 → 検証 → 改善ループ
- 成功している AI-DLC 実装は以下を重視:
  - 観測可能な成功基準
  - 代替案比較のある設計判断
  - 並列実行可能な作業の識別
  - 自己レビュー + 外部レビューの 2 層品質担保
  - 振り返りによる次サイクル改善

## 引用元

- AWS AI-DLC 概念（一般的な業界知識）
- `plugins/totto2727/skills/skill-reviewer/SKILL.md` — Sequential Workflow パターンの具体例
- 設計パターンの分類（`skill-reviewer/SKILL.md` で参照されている 5 種パターン）

## 設計への含意

- **本プラグインは 3 フェーズ構成** (Inception / Construction / Verification) を採用（Operations は本サイクルの範疇外）
- **各フェーズに複数ステップ**を持たせ、ステップごとに Specialist を起動:
  - Inception: Intent Clarification / Research / Design / Task Decomposition
  - Construction: Implementation / Self-Review
  - Verification: External Review / Validation / Retrospective
- **並列可能なステップ** (Research, Implementation, External Review) と **直列必須のステップ** (Design, Task Decomposition, Self-Review, Validation) を明示
- **Self-Review (Step 6) と External Review (Step 7) を分離**: 前者は実装者チーム内の整合性、後者は独立観点からの品質検証
- **Retrospective (Step 9)** を必ず含めてサイクル改善の土台にする

## 残存する不明点

- Validation の実測手法（自動テスト / メトリクス / シナリオ）のうちどれを重点に置くかはプロジェクトや成功基準による。プラグインとしては全方式をサポートする設計とする
- Operations フェーズ（デプロイ・監視・運用）を将来追加するかは別サイクル判断
