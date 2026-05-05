# Intent Spec: feed-platform Workspace Foundation

- **Identifier:** feed-platform-ms-01-workspace-foundation
- **Author:** totto2727 (Main 起草)
- **Created at:** 2026-05-04T12:55:38Z
- **Last updated:** 2026-05-05T00:00:00Z
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
- **BFF (Backend-for-Frontend) の配置: バックエンド側に主配置 + Web フロントエンド側に SSR + 軽量 BFF** (Q2.6 確定 — 2026-05-05)
  - **バックエンド側 BFF**: DB / イベントストア / 業務ロジックへのアクセスを伴う API は全てバックエンド側に配置 (= design-hint L9 の "Resource-Oriented BFF" の物理配置先)。後述「認証認可アーキテクチャ」のリソースサーバーに相当する
  - **Web フロントエンド側**: サーバーサイドレンダリング (SSR) + バックエンドへのアクセスを必要としない軽量な表示用 API のみ。重い処理 / DB 直接アクセスは全てバックエンド側 BFF に転送
  - 根拠: DB / イベントストアの所有がバックエンド側に閉じるため、データアクセスを伴う API はバックエンド側で完結する方が信頼境界 / レイテンシ / 認可判定を単純化できる
- **認証認可アーキテクチャ大枠** (Q2.7 確定 — 2026-05-05、抽象アーキテクチャレベルのみ。具体技術選定は `docs/roadmap/feed-platform/design-hint.md` の「認証認可アーキテクチャの素案」参照)
  - 4 種の構成要素:
    1. **クライアント** — Web フロントエンド (将来 mobile / CLI 等を含む) が OAuth 2.1 クライアントとして JWT を取得・保持
    2. **基幹サーバー (Authorization Server)** — 認証 (パスワード / Passkey / Magic Link 等) + 組織・メンバー・ロール管理 + OAuth 2.1 認可フロー + JWT 発行 + JWKS 公開を担う。**認証認可情報の唯一のソース・オブ・トゥルース** (DB を所有)
    3. **リソースサーバー** — バックエンド側 BFF / API 群がこれに相当。JWT 検証 (JWKS キャッシュ) + 認可判定 (in-memory ポリシーエンジン) + ビジネスロジック実行を担う。**認証認可 DB を共有しない**
    4. **共有 authz レイヤー** — ロール定義 + ポリシー (ロール × 操作の許可マッピング) を Git 管理コードとして配布。リソースサーバー群に import される
  - 認証認可フロー: クライアント → (OAuth 2.1 + PKCE) → 基幹サーバー → JWT 発行 → クライアント → (Bearer JWT) → リソースサーバー → ローカル JWT 検証 + ローカル認可判定 → ビジネスロジック実行。**通常リクエスト経路に基幹サーバー問い合わせは発生しない** (アクセスはログイン時 / トークン更新時のみ)
  - **拡張パスを不変インターフェースで吸収**: 認可判定インターフェース (`can(jwt, resource, action)` 相当) を不変に保ったまま、内部実装を段階的に進化可能とする構造を採用 (Phase 1: 静的ポリシー → ... → Phase N: 独立 PDP 等)。具体段階定義は design-hint 参照

### 未確定 (後続ターンで追記)

- **基幹サーバー (Authorization Server) の配置先**: バックエンドプロジェクト内の 1 サブシステムとするか / 独立プロジェクト (例: `js/app/feed-platform-auth/`) とするか — ms-02 マイルストーンに委譲する案も含めて要検討
- バックエンド / Web フロントエンドそれぞれのパッケージ命名規約
- 共有 authz レイヤーの配置先 (将来の `js/package/` 共通ライブラリ候補)
- ms-01 のスコープ: バックエンドと Web フロントエンドの両方の雛形を ms-01 内で立ち上げるか、片側を後続マイルストーンに委譲するか
- 雛形整備の対象範囲 (Lint / Format / 型チェック / テスト / ビルド設定の境界 — 2 プロジェクトそれぞれ別個)
- 横断 ADR の起票範囲 (再評価必要 — Q2.5 / Q2.6 / Q2.7 確定で ADR 候補が増加したため Q3 を再構成する)

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
