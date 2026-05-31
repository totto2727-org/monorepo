# totto2727-dev-flow

Claude Code 互換エージェント向けのロードマップ管理プラグインです。

このプラグインは上位の roadmap レイヤーと共有ドキュメントフォーマットだけを保持します。Intent / Research / Implementation / Review / Validation / PR・CI 連携などの workflow レベルの実行は oh-my-codingagent に委任します。

## Skills

- `roadmap` — roadmap 作成・マイルストーン追跡の入口。
- `roadmap-intent` — roadmap の世界観、スコープ、非スコープ、成功境界を確定。
- `roadmap-decomposition` — roadmap を観測可能な milestone に分割。
- `roadmap-retrospective` — roadmap レベルの学びを集約。
- `share-artifacts` — roadmap / milestone / ADR と、互換のために残す workflow 系ドキュメントフォーマット。
- `share-adr` — ADR の書き方。

## State management

`docs/roadmap/<roadmap-id>/progress.yaml` は repository 独自の roadmap CLI (`@totto2727/roadmap`) で参照・変更します。直接編集は CLI 実装作業を除いて行いません。
