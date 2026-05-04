# Intent Spec: feed-platform Workspace Foundation

- **Identifier:** feed-platform-ms-01-workspace-foundation
- **Author:** totto2727 (Main 起草)
- **Created at:** 2026-05-04T12:55:38Z
- **Last updated:** 2026-05-04T13:25:00Z
- **Roadmap:** `feed-platform` / milestone `ms-01-workspace-foundation`

## Background

(Step 1 対話で確定 — TBD)

## Purpose

(Step 1 対話で確定 — TBD)

## Scope

Step 1 対話で 1 つずつ確定し追記する (会話駆動・漸増方式)。

### 確定済み

- **採用ワークスペース: `js/`** (Q2 確定 — 2026-05-04)
  - 根拠: ロードマップ Intent 明示推奨 (`docs/roadmap/feed-platform/roadmap.md:65`)、既存スキル群 (`effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp` / `remix`) との整合性最大、CQRS / イベントソーシング / サーバレス BFF の参照実装が monorepo 内に既存
  - 詳細根拠は ms-01 で起票する ADR の最初の 1 本として記録予定
- **プロジェクト分割: バックエンド + Web フロントエンド の 2 プロジェクト構成** (Q2.5 確定 — 2026-05-04 改訂)
  - 旧案 (単一 `js/app/feed-platform/`) は破棄。バックエンドと Web フロントエンドで技術選定が大きく異なる見込みのため、最初から 2 プロジェクトに分離する
  - **バックエンド**: 入力アダプタ / 出力アダプタ / 永続化 / 定期実行 / AI 要約等のサーバーサイド全般を含む (詳細は後続マイルストーン責務)
  - **Web フロントエンド**: 現状想定は Hono + Remix v3 ベースの Web UI。「Web」を限定子として明示し、将来 mobile / desktop クライアントが出力プラグインとして追加される際に、それらは別プロジェクトとして起こせる構造を保つ
  - パッケージ分割の更なる細分化 (BFF 別 / Worker 別 / 共通 library 切り出し) は引き続き YAGNI 方針で、後続マイルストーンの設計で必要になり次第実施

### 未確定 (後続ターンで追記)

- **BFF (Backend-for-Frontend) の配置先**: Web フロントエンド側に吸収するか / バックエンド側に置くか / 独立プロジェクトとするか — 要検討
- バックエンド / Web フロントエンドそれぞれのパッケージ命名規約 (BFF 配置の確定後に詰める)
- ms-01 のスコープ: バックエンドと Web フロントエンドの両方の雛形を ms-01 内で立ち上げるか、片側を後続マイルストーンに委譲するか
- 雛形整備の対象範囲 (Lint / Format / 型チェック / テスト / ビルド設定の境界 — 2 プロジェクトそれぞれ別個)
- 横断 ADR の起票範囲 (再評価必要 — Q2.5 改訂で「プロジェクト分割」自体が ADR 候補に追加されたため、Q3 を再構成する)

## Out of scope

(Step 1 対話で確定 — TBD)

## Success criteria

Step 1 対話で 1 つずつ確定し追記する (会話駆動・漸増方式)。観測可能な形で記述する。

- (TBD)

## Constraints

(Step 1 対話で確定 — TBD)

## Related links

- ロードマップ: `docs/roadmap/feed-platform/roadmap.md`
- マイルストーン: `docs/roadmap/feed-platform/milestones/ms-01-workspace-foundation.md`
- ロードマップ設計素案: `docs/roadmap/feed-platform/design-hint.md`
- ロードマップ進捗: `docs/roadmap/feed-platform/roadmap-progress.yaml`

## Open questions

Step 1 対話の進行に伴って追記。

- (TBD)
