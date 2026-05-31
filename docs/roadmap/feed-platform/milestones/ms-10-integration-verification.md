# Milestone: Integration Verification

- **Milestone ID:** ms-10-integration-verification
- **Roadmap ID:** feed-platform
- **Status:** planned
- **Created at:** 2026-05-04T00:00:00Z
- **Last updated:** 2026-05-04T00:00:00Z

このドキュメントは `roadmap` の **Step 2 (Milestone Decomposition)** で `roadmap-planner` Specialist が起草する**1 マイルストーンの定義書**。本マイルストーンは「最終マイルストーン = 統合検証マイルストーン」のパターン (`plugins/totto2727-dev-flow/skills/share-artifacts/references/milestone.md` 参照) で配置されている。

## 目的

`ms-01`〜`ms-09` で構築された全領域 (認証認可 / 永続化 / 入力プラグイン / 出力プラグイン / 定期実行 / AI 要約) を組み合わせた**End-to-End シナリオ動作確認 + ユーザー受け入れ**を行い、ロードマップ全体の Intent 「目的: 多様入力・多様出力フィード収集配信プラットフォームを 6 つの関心領域が疎結合かつ独立進化可能な構造として整備」が達成されていることを目視・体験で合意する。

## 到達点 (定性)

- ユーザー (totto2727) が Web UI で Passkey または Magic Link でログインできる
- 個人 Organization にて、入力プラグイン (RSS 等の参照アダプタ) で取得されたフィードが定期実行基盤の周期起動で自動取得され、Event Source of Truth に記録される
- 取得されたフィードが出力プラグイン参照アダプタ (Web UI) で閲覧でき、Read-Your-Write 整合戦略 (Tier 1 / Tier 2) が体感される
- AI 要約機能でフィードを要約でき、要約結果が出力プラグイン経由で配信される
- 期間限定共有でフィードを共有でき、共有期間内のみ受信者がアクセスでき、期間満了で自動失効する
- 全 6 領域が**独立サーバレス関数 (マイクロサービス境界)** として疎結合に動作している (1 領域の変更が他領域に波及しないことが構造的に確認できる)
- 「コードレベル契約による入出力プラグイン拡張可能性」が新規アダプタ追加によって実証される (例: ms-06 / ms-07 で実装された参照アダプタとは別の追加アダプタを 1 つ簡易実装し、契約遵守だけで動作することを確認)
- ロードマップ全体に対する目視レビューと残存課題の洗い出しが行われ、`docs/retrospective/roadmap-feed-platform.md` (Step 4 で `roadmap retrospective step` が生成) への入力として整理されている

## スコープ

- 対象シナリオ: 全 6 領域横断の End-to-End シナリオ (ログイン → フィード取得 → 閲覧 → 要約 → 共有)
- 対象実証: コードレベル契約による拡張可能性 (新規アダプタ追加による実証)
- 対象ドキュメント: 残存課題リスト、End-to-End シナリオの観測ログ、Step 4 Roadmap Retrospective への入力整理

## 非スコープ

- 新規機能の追加 (本マイルストーンは検証中心、機能追加は ms-01〜ms-09 で完了済み)
- 本番デプロイ自動化 / CI 構築 (Intent 非スコープ)
- 性能チューニング / 可用性 SLO 設定 (Intent 非スコープ、配下サイクルの個別 Intent Spec で持つ責務)
- マルチテナント以上の SaaS 化 (Intent 非スコープ)

## 依存マイルストーン

- `ms-04-auth-shared-access`: 認証認可基盤の最終形 (期間限定共有を含む) が前提
- `ms-08-scheduler-platform`: 入力プラグインの定期実行統合が前提
- `ms-09-ai-summary`: AI 要約の End-to-End 動作確認が前提

## 関連 oh-my-codingagent execution サイクル (workflow_identifiers)

| サイクル `<identifier>` | 状態 | コメント |
| ----------------------- | ---- | -------- |
| (未起動)                | -    | -        |

## 想定 oh-my-codingagent execution サイクル数

1 (推奨)

検証中心の小規模サイクル。`plugins/totto2727-dev-flow/skills/share-artifacts/references/milestone.md` の「最終マイルストーン = 統合検証マイルストーン」配置パターンに従い、通常の oh-my-codingagent execution サイクル (本ファイルテンプレート) で表現する。

## 補足 / 留意事項

- 本マイルストーン完了後、`roadmap` Step 4 (Roadmap Retrospective) に進み、`roadmap retrospective step` がロードマップ全体の総括を `docs/retrospective/roadmap-feed-platform.md` として生成する
- 本マイルストーンの配下 oh-my-codingagent execution サイクルは「機能追加なしの統合検証 + 残存課題洗い出し」に専念し、検証中に新規発見された深刻な不具合は別途 hotfix サイクルとして起動する (本マイルストーン内で抱え込まない)
- `design-hint.md` のライフサイクル方針「配下 oh-my-codingagent execution サイクルで具体構造が確定後に削除 or ADR 昇格」の最終判断は本マイルストーンで行う (削除 or 抽出すべき ADR 項目の確定)
