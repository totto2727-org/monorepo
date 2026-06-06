# Milestone: Auth — RBAC + Organization

- **Milestone ID:** ms-03-auth-rbac-organization
- **Roadmap ID:** feed-platform
- **Status:** planned
- **Created at:** 2026-05-04T00:00:00Z
- **Last updated:** 2026-05-04T00:00:00Z

## 目的

3 ロール (Admin / Member / Guest 固定) の RBAC と、個人 Organization (自動生成) / 汎用 Organization の 2 種別を導入し、後続マイルストーンが「Organization 単位のリソース」「ロールに応じた操作可否」を扱える土台を成立させる。

## 到達点 (定性)

- ユーザーがサインアップすると個人 Organization が自動生成される
- ユーザーが汎用 Organization を新規作成・参加・脱退できる
- 各 Organization 内でユーザーが Admin / Member / Guest のいずれかのロールを持つ
- 任意のリソース操作に対して 3 ロールの可否が判定される共通の認可レイヤが API 層に組み込まれている
- ユーザーが現在の Organization コンテキストを切り替えられる (個人 ↔ 汎用 / 汎用 A ↔ 汎用 B)
- 認可の許可 / 拒否がテストケースとして網羅され `vp test` で green を維持している
- RBAC 設計 (3 ロール固定 / カスタムロール非対応) と Organization 種別の責務分離が ADR として確定している

## スコープ

- 対象モジュール: 認証基盤パッケージに追加される Authorization レイヤ、Organization モデル、Role モデル
- 対象機能: 個人 Organization 自動生成、汎用 Organization 作成 / メンバー管理、ロール割り当て、認可判定 API、Organization コンテキスト切替
- 対象 ADR: RBAC 3 ロール固定の理由、Organization 2 種別の責務境界、認可判定の配置レイヤ (API 入口 / リポジトリ層 / Aggregate 内 等のいずれか)

## 非スコープ

- 期間限定共有 — `ms-04-auth-shared-access` の責務 (RBAC との統合可否は ms-04 内で詰める)
- カスタムロール定義 / ABAC / OPA 等のポリシー言語統合 (Intent 非スコープ)
- 永続化基盤の Aggregate 単位 RBAC 統合 — `ms-05-persistence-event-store` で具体実装するが、本マイルストーンでは認可判定の抽象 API までを提供する
- マルチテナント以上の SaaS 化 (Intent 非スコープ)

## 依存マイルストーン

- `ms-02-auth-passkey-magiclink`: ユーザーモデルとセッション基盤が前提 (Organization は User に紐付くため)

## 関連 oh-my-codingagent execution サイクル (workflow_identifiers)

| サイクル `<identifier>` | 状態 | コメント |
| ----------------------- | ---- | -------- |
| (未起動)                | -    | -        |

## 想定 oh-my-codingagent execution サイクル数

1 (推奨)

RBAC と Organization は密結合 (Organization 内ロール) のため統合サイクルで扱う。サイクル内で Step 3 (Design) において「個人 Organization 自動生成のトリガー位置」「Organization 切替の API 形」を確定する。

## 補足 / 留意事項

- 本マイルストーン完了後、後続の入力 / 出力プラグイン基盤マイルストーン (ms-06 / ms-07) は「Organization スコープのリソース」として実装可能になる
- 「期間限定共有」(ms-04) は RBAC 統合 (Guest ロール + 期限フィールド付与で表現する案) を視野に入れて Authorization レイヤを設計するが、最終確定は ms-04 で行う
- Organization の物理永続化方式 (専用テーブル / イベントソーシング) は配下サイクル Step 3 (Design) で `ms-05-persistence-event-store` の方針と整合させる
