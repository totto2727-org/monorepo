# Research Note: Claude Code Agent Hierarchy Constraints

- **Identifier:** 2026-04-24-ai-dlc-plugin-bootstrap
- **Topic:** claude-code-constraints
- **Researcher:** （会話中に claude-code-guide エージェントへ委譲して調査）
- **Created at:** 2026-04-24T13:20:00Z
- **Scope:** Claude Code のエージェント階層仕様、Teammate 機能の制約、これらが AI-DLC 設計に与える影響

## 調査対象

Main / Orchestrator / Specialist の 3 層構成を AI-DLC で採用できるかどうか、Claude Code の仕様で検証する。特に:

- サブエージェントが別のサブエージェントを起動できるか
- Teammate / Team 機能で階層的な協調は可能か
- 制約がある場合、その理由（設計思想）

## 発見事項

- **サブエージェントのネストは禁止**: 公式ドキュメント (subagents.md, L60, L714-715) に「Subagents cannot spawn other subagents.」と明記
- **Team の Lead 固定**: agent-teams.md に「No nested teams: teammates cannot spawn their own teams or teammates. Only the lead can manage the team.」および「Lead is fixed: the session that creates the team is the lead for its lifetime.」
- **制約の理由** (3 点):
  1. コスト管理: 階層的な爆発的増殖を防止
  2. コンテキスト管理: 各エージェントの独立したコンテキストウィンドウ構造
  3. 調整可能性: Lead が全体を把握・制御できる単一の階層構造

## 引用元

- Claude Code 公式ドキュメント: `subagents.md` L60, L714-715
- Claude Code 公式ドキュメント: `agent-teams.md` （"No nested teams" および "Lead is fixed" のセクション）
- claude-code-guide エージェント調査結果（会話ログ）

## 設計への含意

- **3 層構成（Main → Orchestrator → Specialist）は実装不可能**。Orchestrator をサブエージェントとして独立させると、Specialist を起動するために Main に指示を戻す必要があり、1 往復分のオーバーヘッドが増えるだけ
- **Orchestrator の責務を Main に統合**し、2 層（Main / Specialist）構成にする
- Orchestrator の役割（進捗管理・ゲート判定・Specialist への指示起案）は Main が全て担う
- Specialist は引き続き独立したサブエージェント（並列起動可）として設計できる
- **本 AI-DLC プラグインのスキル構造は、この制約を前提に設計される**必要がある → main-workflow / main-inception / main-construction / main-verification すべて Main が読む前提

## 残存する不明点

- Team 機能を使った場合と `Agent` ツールで直接サブエージェントを起動する場合で、ライフサイクル挙動に差があるか（本サイクルでは Agent ツール前提で設計）
- セッションをまたいだ Specialist 再利用の可否（本サイクルでは「禁止」とする設計判断）
