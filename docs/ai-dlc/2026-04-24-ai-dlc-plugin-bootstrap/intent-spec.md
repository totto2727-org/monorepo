# Intent Spec: AI-DLC Plugin Bootstrap

- **Identifier:** 2026-04-24-ai-dlc-plugin-bootstrap
- **Author:** totto2727（ユーザー要求） / Main（逆算的に再構築）
- **Created at:** 2026-04-24T13:00:00Z
- **Last updated:** 2026-04-24T13:30:00Z

## 背景

ユーザー（totto2727）が独自の claude-plugin として AI-DLC (AI-Driven Development Lifecycle) ワークフローを運用したい、との要求があった。Agents Team 前提でマルチエージェント開発を回すにあたり、Main / Orchestrator / Specialist の役割分離・ゲート式進行・成果物駆動ハンドオフなど、体系化されたフローが必要だった。

既存の `adr` スキルや `effect-*` スキルはあるが、開発ライフサイクル全体をカバーするフレームワークはプロジェクト内に存在しなかった。また、Claude Code 特有のエージェント階層制約（サブエージェントが更なるサブエージェントを起動できない）を考慮した設計が必須である。

## 目的

Claude Code 環境で動作する AI-DLC プラグインを、1 人の Main エージェント + N 体の専門 Specialist エージェントの体制で実行できる形で提供する。ワークフローの全ステップ・成果物・コミット規約・中断再開プロトコルが文書化されており、別セッションや別ユーザーが同じ設計思想で作業を継承できる状態を目指す。

## スコープ

- `plugins/ai-dlc/` プラグインのリポジトリ内配置
- ワークフロー全体を管理するスキル（main-workflow）
- Phase ごとのフェーズスキル（main-inception / main-construction / main-verification）
- 各 Specialist の役割別スキル（specialist-\* 9 体）と共通基盤（specialist-common）
- 成果物の書き方とテンプレート（shared-artifacts）
- サブエージェント起動エントリポイント（agents/\*.md 9 体）
- ステップ完了時のコミット規約
- サイクル中断再開プロトコル

## 非スコープ

- MCP サーバー連携
- スラッシュコマンド（commands/\*.md）
- Hook による自動実行（hooks/hooks.json）
- 他プロジェクトへの配布・マーケットプレイス公開
- Specialist の実装プロンプトの最終チューニング（将来の Retrospective で反復改善）
- Validation フェーズと Retrospective フェーズの完全実行（本サイクルでは Construction Self-Review まで）
- 実装コード（プラグイン自体は markdown ベース、実行可能コードは含まない）

## 成功基準

- [x] `plugins/ai-dlc/` 配下に `.claude-plugin/plugin.json` と全スキル・エージェントファイルが存在する
- [x] main スキル (4) / specialist スキル (10、common 含む) / shared-artifacts スキル (1) / agents (9) が全て揃っている
- [x] Claude Code 公式仕様（サブエージェント階層制約）と整合した設計になっている
- [x] 成果物の書き方（reference）とテンプレート（template）が 1:1 対応で全 11 成果物に用意されている
- [x] ステップ完了時のコミット規約が明文化されている（1 ステップ = 1 コミット、Implementation を除く）
- [x] ワークフロー中断時、`docs/ai-dlc/<identifier>/` 配下を読むだけで再開可能な構造になっている
- [x] 全スキルが相互参照を通じて一貫した世界観を提示している（旧パスの残存がない）

## 制約

**技術的制約:**

- Claude Code のサブエージェント仕様: サブエージェントが別のサブエージェントを起動できない（公式仕様「Subagents cannot spawn other subagents.」）。Team 機能でも Lead 固定。これにより 3 層構成（Main → Orchestrator → Specialist）は実装不可能
- プラグイン構造: `.claude-plugin/plugin.json`, `skills/`, `agents/` が規定のディレクトリ階層
- Markdown のみで記述（実行可能コードやスクリプトは持たない）

**組織的制約:**

- 作業者は totto2727（Main 兼 設計者）。本サイクルは単独実行

**規範的制約:**

- 既存のスキル命名規則（`<name>/SKILL.md`）を踏襲
- コミットメッセージは既存プロジェクトの Conventional Commits 様式に従う
- GPG 署名を維持（`--no-gpg-sign` は使わない）

## 関連リンク

- Claude Code 公式ドキュメント: subagents.md, agent-teams.md（階層制約の根拠）
- 既存スキル参照: `plugins/totto2727/skills/adr/`（ADR との使い分け判断の参考）
- 既存プラグイン例: `plugins/totto2727/`, `plugins/moonbit/`, `plugins/components-build/`

## 未解決事項

- Validation（Step 8）の実測は本サイクルでは未実施。実際のサイクル（別機能の開発）で動作確認する必要がある
- Retrospective（Step 9）は本サイクル終了時に実施予定（Self-Review 後）
- Specialist プロンプトの実使用テスト: 実際にサブエージェントとして起動した際の振る舞い確認は別途必要
- プラグインマーケットプレイスへの公開方針は未定
