---
confirmed: false
---

# ADR: researcher Specialist の言語固有スキル棚卸し提案を保留

## Context

`2026-04-26-add-qa-design-step` サイクルで researcher が言語固有スキル (effect-layer / totto2727-fp / vite-plus 等) を能動的に棚卸ししたことが高品質な成果物に繋がった。retrospective ではこれを一般化し、specialist-researcher 本文に「該当言語のプロジェクト固有スキル棚卸し」観点をデフォルト調査項目として明示する改善案が出された。

`2026-04-29-retro-cleanup` サイクルで本提案を再評価した結果、以下のトレードオフが浮上した:

- **追記する場合**: researcher 本文が肥大化、スキル discovery のキーワード抽象度が下がる
- **追記しない場合**: Claude Code の自動ロード機構 (skill discovery) に依存、研究者が必要なスキルを見落とす可能性

## Decision

本提案を **本サイクルでは対応せず保留**。Claude Code の自動ロード機構 (skill discovery) に期待し、Specialist 起動コンテキストに必要な言語固有スキルが暗黙に含まれることを前提とする。

## Impact

- researcher 本文への明示的な棚卸しルールは追加しない
- 各サイクルで必要な言語固有スキルは Claude Code 側のトリガーマッチングで自動的に有効化されることを前提
- サイクル中に「言語固有スキルの取りこぼし」起因の Blocker / Major が発生する可能性は残るが、現状そのような事象は観測されていない

## 再検討トリガー

以下のいずれかが満たされた時点で本判断を再評価する:

1. Claude Code の skill discovery 仕様変更 (動的ロード廃止 / トリガー精度低下 / 同時アクティブスキル数上限の変更等)
2. dev-workflow サイクルで「必要な言語固有スキルにアクセスできなかった」起因の Blocker / Major が 1 件以上発生
3. dev-workflow CLI 化により Specialist 起動コンテキストを明示制御する設計が固まったとき (CLI 側で棚卸しを担当できる場合、本ルールを CLI 仕様に統合)

## 関連サイクル

- `docs/dev-workflow/2026-04-26-add-qa-design-step/` (出典サイクル、retrospective.md は `2026-04-29-retro-cleanup` の C-4 で削除済み — git 履歴から参照可)
- `docs/dev-workflow/2026-04-29-retro-cleanup/` (本判断を確定したサイクル、Intent Spec の「対応せず」スコープ参照)
